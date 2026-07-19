# frozen_string_literal: true

class AppMessage < ApplicationRecord
  belongs_to :student

  validates :title, presence: true

  scope :unread, -> { where(read_at: nil) }

  def read?
    read_at.present?
  end

  def mark_read!
    update!(read_at: Time.current) unless read?
  end
end
