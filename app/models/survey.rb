# frozen_string_literal: true

class Survey < ApplicationRecord
  attribute :questions, :json
  belongs_to :course, optional: true
  has_many :survey_responses, dependent: :destroy

  TYPES = %w[pre_training daily post_exam].freeze
  validates :title, presence: true
  validates :survey_type, inclusion: { in: TYPES }

  scope :active, -> { where(active: true) }
end
