# frozen_string_literal: true

class Tag < ApplicationRecord
  CATEGORIES = %w[
    applicable_object
    industry
    scale_threshold
    income_threshold
    deadline
    course
    other
  ].freeze

  has_many :student_tags, dependent: :destroy
  has_many :students, through: :student_tags
  has_many :policy_tags, dependent: :destroy
  has_many :policies, through: :policy_tags
  has_many :course_tags, dependent: :destroy
  has_many :courses, through: :course_tags

  validates :name, :category, presence: true
  validates :category, inclusion: { in: CATEGORIES }
  validates :name, uniqueness: { scope: :category }
end
