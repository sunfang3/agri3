# frozen_string_literal: true

class Course < ApplicationRecord
  attribute :longitude, :float
  attribute :latitude, :float
  attribute :published, :boolean
  attribute :deep_tags, :json
  belongs_to :district, optional: true
  belongs_to :mentor, optional: true
  has_many :course_tags, dependent: :destroy
  has_many :tags, through: :course_tags
  has_many :enrollments, dependent: :destroy
  has_many :students, through: :enrollments
  has_many :check_ins, dependent: :destroy
  has_many :training_photos, dependent: :destroy
  has_many :surveys, dependent: :nullify
  has_many :voice_notes, dependent: :nullify

  validates :title, presence: true

  scope :published, -> { where(published: true) }

  def mentor_display
    mentor&.name.presence || mentor_name
  end
end
