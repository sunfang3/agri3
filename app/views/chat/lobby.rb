# frozen_string_literal: true

# Public chat lobby at /chat — not the product root.
class Views::Chat::Lobby < Views::Base
  def initialize(nickname: nil, messages: [], identity: nil, locked: false)
    @nickname = nickname
    @messages = messages
    @identity = identity || ChatIdentity.new(nickname:)
    @locked = locked
  end

  def view_template
    return render Components::Chat::NicknameGate.new(identity: @identity) unless @nickname

    div(class: "flex h-dvh min-h-[34rem] w-full bg-base-200/50 sm:p-4", data: { chat_nickname: @nickname }) do
      render Components::Chat::Room.new(author: @nickname, messages: @messages, locked: @locked)
    end
  end
end
