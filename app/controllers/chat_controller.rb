# frozen_string_literal: true

# Public lobby at /chat — real-time via Litecable (Action Cable) + Turbo Streams.
class ChatController < ApplicationController
  include ChatNicknameResolvable

  def show
    nickname = resolve_chat_nickname!
    messages = nickname ? ChatMessage.recent_for("lobby") : []
    locked = platform_chat_nickname?

    render Views::Chat::Lobby.new(nickname:, messages:, locked:)
  end
end
