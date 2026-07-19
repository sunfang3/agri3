# frozen_string_literal: true

class StudentTag < ApplicationRecord
  attribute :user_corrected, :boolean
  belongs_to :student
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :student_id }
end
