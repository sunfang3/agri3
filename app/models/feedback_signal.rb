# frozen_string_literal: true

class FeedbackSignal < ApplicationRecord
  belongs_to :student
  belongs_to :matchable, polymorphic: true

  SIGNAL_TYPES = %w[useful not_useful applied completed].freeze
  validates :signal_type, inclusion: { in: SIGNAL_TYPES }
end
