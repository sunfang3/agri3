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
  # 市直班：无归属区县；区办班：district_id 指向开班区县
  scope :city_direct, -> { where(district_id: nil) }
  scope :for_district, ->(district_id) { where(district_id: district_id) }

  def city_direct?
    district_id.nil?
  end

  def reviewer_label
    city_direct? ? "市级管理员" : "区县管理员"
  end

  def ownership_label
    city_direct? ? "市直班" : (district&.name.presence || "区办班")
  end

  def mentor_display
    mentor&.name.presence || mentor_name
  end
end
