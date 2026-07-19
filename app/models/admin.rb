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

  def scoped_enrollments
    city_admin? ? Enrollment.all : Enrollment.joins(:student).where(students: { district_id: district_id })
  end
end
