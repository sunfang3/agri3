# frozen_string_literal: true

require "stringio"
require "zlib"

def attach_example(attachment)
  return if attachment.attached?

  image_blob = ActiveStorage::Blob.find_by(key: "qilu-demo-field-v1") || ActiveStorage::Blob.create_and_upload!(key: "qilu-demo-field-v1", io: StringIO.new(field_png), filename: "演示田间记录.png", content_type: "image/png")
  attachment.attach(image_blob)
end

def attach_audio(attachment)
  return if attachment.attached?

  pcm = "\x80".b * 8000
  wave = "RIFF" + [ 36 + pcm.bytesize ].pack("V") + "WAVEfmt " + [ 16, 1, 1, 8000, 8000, 1, 8 ].pack("VvvVVvv") + "data" + [ pcm.bytesize ].pack("V") + pcm
  audio_blob = ActiveStorage::Blob.find_by(key: "qilu-demo-audio-v1") || ActiveStorage::Blob.create_and_upload!(key: "qilu-demo-audio-v1", io: StringIO.new(wave), filename: "演示静音录音.wav", content_type: "audio/wav")
  attachment.attach(audio_blob)
end

def field_png
  width, height = 160, 100
  pixels = height.times.map do |y|
    "\0".b + width.times.map do |x|
      color = if (x - 125)**2 + (y - 20)**2 < 100
        [ 237, 184, 28 ]
      elsif y < 40
        [ 89, 173, 196 ]
      elsif (x + y / 2) % 22 < 5
        [ 170, 132, 71 ]
      else
        [ 67, 125 + y / 4, 78 ]
      end
      color.pack("C3")
    end.join
  end.join
  chunk = ->(type, data) { [ data.bytesize ].pack("N") + type + data + [ Zlib.crc32(type + data) ].pack("N") }
  "\x89PNG\r\n\x1a\n".b + chunk.call("IHDR", [ width, height, 8, 2, 0, 0, 0 ].pack("NNCCCCC")) + chunk.call("IDAT", Zlib::Deflate.deflate(pixels)) + chunk.call("IEND", "")
end
