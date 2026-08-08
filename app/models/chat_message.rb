# frozen_string_literal: true

class ChatMessage < ApplicationRecord
  attribute :created_at, :datetime
  attribute :updated_at, :datetime

  before_validation :normalize_text

  validates :room, presence: true
  validates :author, length: { in: 2..20 }
  validates :body, length: { in: 1..500 }

  # Stream name parts for turbo_stream_from / Phlex::Reactive.broadcast_to
  # (Litecable via Turbo Streams Channel over Action Cable).
  def self.stream_key(room) = [ "chat", room.to_s ]

  def self.recent_for(room, limit: 50)
    newest_ids = where(room:).order(created_at: :desc, id: :desc).limit(limit).select(:id)
    where(id: newest_ids).order(:created_at, :id)
  end

  def display_time
    t = created_at
    t = Time.zone.parse(t.to_s) if t && !t.respond_to?(:strftime)
    t&.strftime("%H:%M") || ""
  rescue ArgumentError, TypeError
    ""
  end

  def display_time_iso
    t = created_at
    t = Time.zone.parse(t.to_s) if t && !t.respond_to?(:iso8601)
    t&.iso8601 || ""
  rescue ArgumentError, TypeError
    ""
  end

  private

  def normalize_text
    self.author = author.to_s.strip
    self.body = body.to_s.strip
    self.room = room.to_s.strip.presence || "lobby"
  end
end
