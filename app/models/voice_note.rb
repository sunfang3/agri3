# frozen_string_literal: true

class VoiceNote < ApplicationRecord
  attribute :structured, :json
  belongs_to :student
  belongs_to :course, optional: true

  STATUSES = %w[pending transcribed structured failed].freeze
  validates :status, inclusion: { in: STATUSES }
end
