# frozen_string_literal: true

class Attribution < ApplicationRecord
  attribute :details, :json
  belongs_to :student
  belongs_to :matchable, polymorphic: true, optional: true

  OUTCOMES = %w[income_up honor enrollment_complete].freeze
  validates :outcome_type, inclusion: { in: OUTCOMES }
end
