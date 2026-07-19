# frozen_string_literal: true

module VoiceNotes
  # ASR + LLM structured extraction pipeline via adapters.
  class Pipeline
    def initialize(asr: Adapters::FakeAsr.new, llm: Adapters::FakeLlm.new)
      @asr = asr
      @llm = llm
    end

    def process!(voice_note, audio_source: nil)
      transcript = @asr.transcribe(audio_source || voice_note.audio_key || "silent")
      voice_note.update!(transcript: transcript, status: "transcribed")

      structured = @llm.structure(transcript)
      voice_note.update!(structured: structured, status: "structured")
      voice_note
    rescue StandardError => e
      voice_note.update!(status: "failed", structured: { "error" => e.message })
      voice_note
    end
  end
end
