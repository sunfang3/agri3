# frozen_string_literal: true

class Components::Chat::Room < Components::Base
  include Phlex::Rails::Helpers::TurboStreamFrom

  def initialize(room: "lobby", author:, messages: [], locked: false)
    @room = room
    @author = author
    @messages = messages
    @locked = locked
  end

  def view_template
    # Subscribes via Turbo Streams Channel over Action Cable (Litecable adapter).
    turbo_stream_from(*ChatMessage.stream_key(@room))

    section(class: "chat-shell mx-auto flex min-h-0 w-full max-w-5xl flex-1 flex-col border-x border-base-300 bg-base-100", data: { testid: "chat-room" }) do
      render_header

      div(id: messages_id, class: "chat-messages min-h-0 flex-1 space-y-1 overflow-y-auto px-4 py-5 sm:px-7", data: { testid: "chat-messages" }) do
        @messages.each { |message| render Components::Chat::Message.new(chat_message: message) }
      end

      footer(class: "border-t border-base-300 bg-base-100 px-4 py-3 sm:px-7 sm:py-4") do
        render Components::Chat::Composer.new(room: @room, author: @author)
      end
    end
  end

  private

  def render_header
    header(class: "flex min-h-18 items-center justify-between gap-4 border-b border-base-300 px-4 py-3 sm:px-7") do
      div(class: "min-w-0") do
        h1(class: "truncate text-lg font-bold") { "公共大厅" }
        div(class: "mt-0.5 flex items-center gap-1.5 text-xs text-base-content/55") do
          render LucideIcon(:radio, class: "size-3.5 text-success", aria: { hidden: true })
          span { "Litecable 实时广播" }
        end
      end

      render_identity
    end
  end

  def render_identity
    div(class: "flex min-w-0 flex-col items-end gap-0.5 px-2", data: { testid: "current-identity" }, aria: { label: "当前昵称 #{@author}" }) do
      div(class: "flex min-w-0 items-center gap-2") do
        span(class: "flex size-8 shrink-0 items-center justify-center rounded-full bg-secondary text-xs font-bold text-secondary-content") do
          @author.to_s.first.to_s.upcase
        end
        span(class: "max-w-28 truncate text-sm font-semibold sm:max-w-48") { @author }
      end
      if @locked
        span(class: "text-[10px] text-base-content/50", data: { testid: "platform-identity" }) { "系统账号" }
      end
    end
  end

  def messages_id = "chat-messages-#{@room}"
end
