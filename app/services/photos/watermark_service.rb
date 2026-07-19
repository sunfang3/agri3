# frozen_string_literal: true

module Photos
  class WatermarkService
    def build_watermark(taken_at:, latitude: nil, longitude: nil, place: nil)
      parts = []
      parts << (taken_at || Time.current).strftime("%Y-%m-%d %H:%M")
      parts << place if place.present?
      if latitude.present? && longitude.present?
        parts << format("%.5f,%.5f", latitude.to_f, longitude.to_f)
      end
      parts.join(" | ")
    end

    def attach!(training_photo, taken_at: Time.current, place: nil)
      text = build_watermark(
        taken_at: taken_at,
        latitude: training_photo.latitude,
        longitude: training_photo.longitude,
        place: place
      )
      training_photo.update!(
        watermark_text: text,
        taken_at: taken_at,
        storage_key: training_photo.storage_key.presence || "photos/#{training_photo.id || SecureRandom.hex(8)}"
      )
      training_photo
    end
  end
end
