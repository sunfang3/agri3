# frozen_string_literal: true

class MentorAnswer < ApplicationRecord
  belongs_to :student
  belongs_to :mentor, optional: true

  STATUSES = %w[open answered].freeze
  validates :question, presence: true
  validates :status, inclusion: { in: STATUSES }
end
