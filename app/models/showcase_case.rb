# frozen_string_literal: true

class ShowcaseCase < ApplicationRecord
  belongs_to :student
  belongs_to :district, optional: true

  validates :title, presence: true

  scope :published, -> { where(published: true).order(contribution_score: :desc) }
end
