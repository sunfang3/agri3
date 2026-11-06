# frozen_string_literal: true

class Policy < ApplicationRecord
  attribute :published, :boolean
  attribute :parsed_fields, :json
  belongs_to :district, optional: true
  has_many :policy_tags, dependent: :destroy
  has_many :tags, through: :policy_tags
  has_many :policy_interactions, dependent: :destroy
  attribute :valid_until, :date
  has_one_attached :pdf

  PARSE_STATUSES = %w[manual pending_review approved].freeze

  validates :title, presence: true
  validates :parse_status, inclusion: { in: PARSE_STATUSES }

  scope :published, -> { where(published: true) }
  scope :valid_now, -> { where("valid_until IS NULL OR valid_until >= ?", Date.current) }

  def tag_ids=(ids)
    super(Array(ids).reject(&:blank?).map(&:to_i))
  end

  def required_tag_count
    tags.count
  end
end
