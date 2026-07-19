# frozen_string_literal: true

class ResourceGap < ApplicationRecord
  belongs_to :district, optional: true

  GAP_TYPES = %w[policy course mentor].freeze
  SEVERITIES = %w[low medium high critical].freeze

  validates :gap_type, inclusion: { in: GAP_TYPES }
  validates :severity, inclusion: { in: SEVERITIES }
  validates :title, presence: true
end
