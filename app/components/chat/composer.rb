# frozen_string_literal: true

class Components::Chat::Composer < Components::Base
  include Phlex::Reactive::Component

  reactive_state :room, :author, :body, :errors
  action :send_message, params: { body: :string }
  skip_verify_authorized :send_message

  attr_reader :body, :errors

  def initialize(room: "lobby", author:, body: "", errors: [])
    @room = room
    @author = author
    @body = body
    @errors = errors
  end

  def id = "chat-composer-#{@room}"

  def send_message(body:)
    @body = body.to_s.strip
    message = ChatMessage.new(room: @room, author: @author, body: @body)
    return invalid_reply(message) unless message.valid?

    message.save!
    broadcast_to_peers(message)
    reset_form

    reply.replace.stream(Components::Chat::Message.append(target: messages_id, model: message))
  end

  def view_template
    div(**reactive_root(class: "space-y-2", data: { chat_author: @author })) do
      div(class: "flex items-end gap-2") do
        input(**mix(
          on(:send_message, event: "keydown.enter"),
          type: "text",
          name: "body",
          value: @body,
          maxlength: 500,
          autocomplete: "off",
          placeholder: "输入消息...",
          aria: { label: "消息", invalid: @errors.any? },
          class: "input input-bordered h-11 min-w-0 flex-1 bg-base-100"
        ))
        button(**mix(
          on(:send_message, busy: { disable: true }),
          class: "btn btn-primary btn-square size-11 shrink-0",
          aria: { label: "发送消息" },
          title: "发送消息"
        )) { render LucideIcon(:send, class: "size-4", aria: { hidden: true }) }
      end

      p(role: "alert", class: "text-sm text-error") { @errors.to_sentence } if @errors.any?
    end
  end

  private

  def invalid_reply(message)
    @errors = message.errors.full_messages
    reply.replace
  end

  def broadcast_to_peers(message)
    Components::Chat::Message.broadcast_to(
      *ChatMessage.stream_key(@room),
      append: message,
      target: messages_id,
      exclude: reactive_connection_id
    )
  end

  def reset_form
    @body = ""
    @errors = []
  end

  def messages_id = "chat-messages-#{@room}"
end
