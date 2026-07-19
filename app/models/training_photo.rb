# frozen_string_literal: true

class TrainingPhoto < ApplicationRecord
  belongs_to :course
  belongs_to :student, optional: true
  belongs_to :admin, optional: true
  has_one_attached :image
end
