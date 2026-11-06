# frozen_string_literal: true

class VoiceNote < ApplicationRecord
  include ValidatesUpload
  attribute :structured, :json
  has_one_attached :audio
  validates_upload :audio, types: %w[audio/mpeg audio/mp3 audio/mp4 audio/wav audio/x-wav audio/webm audio/ogg], maximum: 50.megabytes
  belongs_to :student
  belongs_to :course, optional: true

  STATUSES = %w[pending transcribed structured failed].freeze
  validates :status, inclusion: { in: STATUSES }
end
