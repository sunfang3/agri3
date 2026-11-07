# frozen_string_literal: true

class ResourceMatch < ApplicationRecord
  attribute :cosine_similarity, :float
  attribute :reason_tags, :json
  belongs_to :student
  belongs_to :matchable, polymorphic: true

  STATUSES = %w[recommended viewed applied dismissed].freeze
  ENGINES = %w[rules cosine].freeze

  validates :score, inclusion: { in: 0..100 }
  validates :status, inclusion: { in: STATUSES }
  validates :engine, inclusion: { in: ENGINES }
  validates :matchable_id, uniqueness: { scope: [ :student_id, :matchable_type ] }

  scope :for_student, ->(student) { where(student_id: student.id) }
  scope :policies, -> { where(matchable_type: "Policy") }
  scope :courses, -> { where(matchable_type: "Course") }
  scope :ranked, -> { order(score: :desc, created_at: :desc) }

  # D3 three-priority hierarchy for student home recommendations
  def priority_tier
    return 3 if score.nil? || score > 100
    return 1 if score >= 80 # 强烈推荐

    score >= 50 ? 2 : 3 # 建议关注 / 可了解
  end

  def priority_label
    { 1 => "强烈推荐", 2 => "建议关注", 3 => "可了解" }.fetch(priority_tier)
  end
end
