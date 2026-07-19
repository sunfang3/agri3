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
    case score
    when 80..100 then 1 # 强烈推荐
    when 50...80 then 2 # 建议关注
    else 3              # 可了解
    end
  end

  def priority_label
    { 1 => "强烈推荐", 2 => "建议关注", 3 => "可了解" }[priority_tier]
  end
end
