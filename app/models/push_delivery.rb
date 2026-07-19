# frozen_string_literal: true

class PushDelivery < ApplicationRecord
  attribute :payload, :json
  belongs_to :student

  CHANNELS = %w[sms webpush wechat_mp].freeze
  STATUSES = %w[queued sent failed].freeze

  validates :channel, inclusion: { in: CHANNELS }
  validates :status, inclusion: { in: STATUSES }
end
