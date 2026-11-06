# frozen_string_literal: true

class TrainingPhoto < ApplicationRecord
  include ValidatesUpload
  attribute :longitude, :float
  attribute :latitude, :float
  belongs_to :course
  belongs_to :student, optional: true
  belongs_to :admin, optional: true
  has_one_attached :image
  validates_upload :image, types: %w[image/jpeg image/png image/webp], maximum: 20.megabytes
end
