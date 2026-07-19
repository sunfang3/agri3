# frozen_string_literal: true

class CourseTag < ApplicationRecord
  belongs_to :course
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :course_id }
end
