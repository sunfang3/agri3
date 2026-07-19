# frozen_string_literal: true

class AnalyticsEvent < ApplicationRecord
  attribute :payload, :json
  EVENT_TYPES = %w[login key_action page_view].freeze

  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }

  belongs_to :actor, polymorphic: true, optional: true

  def self.track!(event_type:, actor: nil, page: nil, action_name: nil, payload: {}, district_code: nil)
    create!(
      event_type: event_type,
      actor_type: actor&.class&.name,
      actor_id: actor&.id,
      page: page,
      action_name: action_name,
      payload: payload,
      district_code: district_code
    )
  end
end
