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

  # Enrollments this admin is allowed to review/confirm.
  # MVP: 审核权跟随「开班主体」，不是学员户籍区。
  # - 市直班 (course.district_id nil) → 市级管理员
  # - 区办班 (course.district_id set) → 对应区县管理员
  def scoped_enrollments
    scope = Enrollment.joins(:course)
    if city_admin?
      scope.merge(Course.city_direct)
    else
      scope.merge(Course.for_district(district_id))
    end
  end
end
