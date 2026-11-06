class CapabilityAssessment < ApplicationRecord
  DIMENSIONS = { "technology" => "技术能力", "management" => "经营管理", "policy" => "政策申报", "marketing" => "品牌营销", "digital" => "电商运营", "leadership" => "示范带动" }.freeze
  belongs_to :student
  attribute :scores, :json
  attribute :assessed_on, :date
  validates :assessed_on, presence: true
  validate :valid_scores
  def average_score = scores.values.sum(&:to_f).fdiv(scores.size.nonzero? || 1).round(1)

  private

  def valid_scores
    unless scores.is_a?(Hash) && scores.keys.sort == DIMENSIONS.keys.sort && scores.values.all? { |v| v.is_a?(Numeric) && v.between?(0, 100) }
      errors.add(:scores, "须包含六项 0–100 分的能力评估")
    end
  end
end
