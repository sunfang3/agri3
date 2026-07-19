# frozen_string_literal: true

class Mentor < ApplicationRecord
  attribute :deep_tags, :json
  belongs_to :district, optional: true
  has_many :courses, dependent: :nullify
  has_many :mentor_answers, dependent: :nullify

  validates :name, presence: true
end
