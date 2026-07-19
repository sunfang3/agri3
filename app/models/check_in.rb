# frozen_string_literal: true

class CheckIn < ApplicationRecord
  belongs_to :enrollment
  belongs_to :student
  belongs_to :course

  validates :token, :checked_in_at, presence: true
end
