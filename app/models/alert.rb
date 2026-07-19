# frozen_string_literal: true

class Alert < ApplicationRecord
  belongs_to :district, optional: true
  belongs_to :source, polymorphic: true, optional: true

  STATUSES = %w[open acknowledged closed].freeze
  SEVERITIES = %w[low medium high critical].freeze

  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :severity, inclusion: { in: SEVERITIES }

  scope :open_alerts, -> { where(status: "open") }
end
