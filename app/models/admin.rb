# frozen_string_literal: true

class Admin < ApplicationRecord
  has_secure_password

  belongs_to :district, optional: true
  has_many :training_photos, dependent: :nullify

  ROLES = %w[district city system].freeze

  validates :name, :email, presence: true
  validates :email, uniqueness: true
  validates :role, inclusion: { in: ROLES }

  def city_admin?
    role.in?(%w[city system])
  end

  def can_manage_district?(district_id)
    city_admin? || self.district_id == district_id
  end

  def scoped_students
    city_admin? ? Student.all : Student.where(district_id: district_id)
  end

  # Enrollments this admin is allowed to review/confirm (录取).
  # - 市直班 (course.district_id nil) → 市级管理员
  # - 区办班 (course.district_id set) → 对应开班区县管理员
  def scoped_enrollments
    scope = Enrollment.joins(:course)
    if city_admin?
      scope.merge(Course.city_direct)
    else
      scope.merge(Course.for_district(district_id))
    end
  end

  # 区知会/备案：本区学员报的市直班（区不录取，只备案）
  def scoped_district_acks
    return Enrollment.none if city_admin?

    Enrollment.joins(:course, :student)
      .merge(Course.city_direct)
      .where(students: { district_id: district_id })
  end

  def pending_district_acks
    scoped_district_acks.ack_pending
  end

  # 市级只读：各区办班报名（不可 bulk_confirm）
  def scoped_district_courses_readonly
    return Enrollment.none unless city_admin?

    Enrollment.joins(:course, :student)
      .includes(:student, :course)
      .where.not(courses: { district_id: nil })
  end
end
