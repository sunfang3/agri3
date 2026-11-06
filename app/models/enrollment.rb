# frozen_string_literal: true

class Enrollment < ApplicationRecord
  attribute :confirmed_at, :datetime
  attribute :district_acked_at, :datetime

  belongs_to :student
  belongs_to :course
  belongs_to :district_ack_admin, class_name: "Admin", optional: true
  has_many :check_ins, dependent: :destroy

  STATUSES = %w[pending enrolled completed dropped].freeze
  # 区知会/备案（仅市直班对本区学员）：not_required | pending | acked
  ACK_STATUSES = %w[not_required pending acked].freeze

  TRANSITIONS = {
    "pending" => %w[enrolled dropped],
    "enrolled" => %w[completed dropped],
    "completed" => [],
    "dropped" => []
  }.freeze

  validates :status, inclusion: { in: STATUSES }
  validates :district_ack_status, inclusion: { in: ACK_STATUSES }
  validates :student_id, uniqueness: { scope: :course_id }
  validate :available_seat, if: -> { status == "enrolled" && will_save_change_to_status? }

  before_validation :assign_district_ack_defaults, on: :create

  scope :pending, -> { where(status: "pending") }
  scope :enrolled, -> { where(status: "enrolled") }
  scope :ack_pending, -> { where(district_ack_status: "pending") }
  scope :ack_acked, -> { where(district_ack_status: "acked") }

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
    course.with_lock do
      raise ArgumentError, "课程名额已满" if course.full?
      transition_to!("enrolled")
      notify_student_admission!
    end
    self
  end

  def complete!
    transition_to!("completed")
  end

  def drop!
    transition_to!("dropped")
  end

  def needs_district_ack?
    district_ack_status == "pending"
  end

  def district_acked?
    district_ack_status == "acked"
  end

  # 区县管理员：对本区学员报名的市直班做知会/备案（不录取）
  def ack_by_district!(admin)
    raise ArgumentError, "only district admins can 备案" if admin.city_admin?
    raise ArgumentError, "only 市直班 needs district 备案" unless course.city_direct?
    raise ArgumentError, "student not in admin district" unless student.district_id == admin.district_id
    raise ArgumentError, "already acked or not required" unless needs_district_ack?

    update!(
      district_ack_status: "acked",
      district_acked_at: Time.current,
      district_ack_admin_id: admin.id
    )
    self
  end

  def self.bulk_confirm!(ids)
    where(id: ids, status: "pending").find_each.map(&:confirm!)
  end

  def status_label
    {
      "pending" => "审核中",
      "enrolled" => "已录取",
      "completed" => "已结业",
      "dropped" => "已取消"
    }[status] || status
  end

  def self.bulk_ack!(ids, admin:)
    where(id: ids, district_ack_status: "pending").find_each.filter_map do |enrollment|
      enrollment.ack_by_district!(admin)
    rescue ArgumentError
      nil
    end
  end

  private

  def available_seat
    return unless course&.capacity.present?

    occupied = course.enrollments.where(status: %w[enrolled completed]).where.not(id: id).count
    errors.add(:course, "名额已满") if occupied >= course.capacity
  end

  def notify_student_admission!
    AppMessage.create!(
      student: student,
      title: "报名已通过",
      body: "您报名的课程「#{course.title}」（#{course.ownership_label}）已审核通过，状态：已录取。" \
            "请留意开班时间与地点：#{course.place.presence || "详见课程通知"}。",
      message_type: "enrollment"
    )
  end

  def assign_district_ack_defaults
    return if district_ack_status.present? && district_ack_status != "not_required"

    self.district_ack_status =
      if course&.city_direct?
        "pending"
      else
        "not_required"
      end
  end
end
