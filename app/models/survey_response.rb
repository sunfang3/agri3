# frozen_string_literal: true

class SurveyResponse < ApplicationRecord
  attribute :answers, :json
  belongs_to :survey
  belongs_to :student

  validates :student_id, uniqueness: { scope: :survey_id }
end
