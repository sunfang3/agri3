# frozen_string_literal: true

class TipsStageRule < ApplicationRecord
  attribute :conditions, :json
  validates :stage, inclusion: { in: Student::TIPS_STAGES }
  validates :name, presence: true

  scope :enabled, -> { where(enabled: true).order(priority: :desc) }

  # conditions example: { "min_scale" => 50, "min_income" => 100000, "min_honors_present" => true }
  def matches?(student)
    c = conditions || {}
    return false if c["min_scale"] && student.scale.to_f < c["min_scale"].to_f
    return false if c["max_scale"] && student.scale.to_f > c["max_scale"].to_f
    return false if c["min_income"] && student.annual_income.to_f < c["min_income"].to_f
    return false if c["max_income"] && student.annual_income.to_f > c["max_income"].to_f
    return false if c["min_honors_present"] && student.honors.blank?
    return false if c["industry"] && student.primary_industry != c["industry"]
    true
  end
end
