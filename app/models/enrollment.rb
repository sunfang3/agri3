# frozen_string_literal: true

class Enrollment < ApplicationRecord
  belongs_to :student
  belongs_to :course
  has_many :check_ins, dependent: :destroy

  STATUSES = %w[pending enrolled completed dropped].freeze

  TRANSITIONS = {
    "pending" => %w[enrolled dropped],
    "enrolled" => %w[completed dropped],
    "completed" => [],
    "dropped" => []
  }.freeze

  validates :status, inclusion: { in: STATUSES }
  validates :student_id, uniqueness: { scope: :course_id }

  scope :pending, -> { where(status: "pending") }
  scope :enrolled, -> { where(status: "enrolled") }

  def can_transition_to?(new_status)
    TRANSITIONS.fetch(status, []).include?(new_status.to_s)
  end

  def transition_to!(new_status)
    new_status = new_status.to_s
    raise ArgumentError, "invalid transition #{status} -> #{new_status}" unless can_transition_to?(new_status)

    attrs = { status: new_status }
    attrs[:confirmed_at] = Time.current if new_status == "enrolled"
    update!(attrs)
    self
  end

  def confirm!
    transition_to!("enrolled")
  end

  def complete!
    transition_to!("completed")
  end

  def drop!
    transition_to!("dropped")
  end

  def self.bulk_confirm!(ids)
    where(id: ids, status: "pending").find_each.map(&:confirm!)
  end
end
