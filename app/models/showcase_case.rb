# frozen_string_literal: true

class ShowcaseCase < ApplicationRecord
  include ValidatesUpload
  attribute :published, :boolean
  has_one_attached :media
  validates_upload :media, types: %w[image/jpeg image/png image/webp video/mp4 video/webm], maximum: 100.megabytes
  belongs_to :student
  belongs_to :district, optional: true

  validates :title, presence: true, length: { maximum: 200 }
  validates :body, length: { maximum: 5000 }

  scope :published, -> { where(published: true).order(contribution_score: :desc) }
end
