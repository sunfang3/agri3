# frozen_string_literal: true

class Components::Chat::Message < Components::Base
  include Phlex::Reactive::Streamable

  def initialize(chat_message:)
    @message = chat_message
  end

  def id = ActionView::RecordIdentifier.dom_id(@message)

  def self.model_param_name = :chat_message

  def view_template
    article(id:, class: "chat chat-start", data: { testid: "message" }) do
      div(class: "chat-image avatar avatar-placeholder") do
        div(class: "flex size-9 items-center justify-center rounded-full bg-base-300 text-xs font-bold text-base-content/70") do
          @message.author.to_s.first.to_s.upcase
        end
      end

      div(class: "chat-header mb-1 flex items-baseline gap-2 text-xs text-base-content/55") do
        span(class: "font-semibold text-base-content/75", data: { testid: "message-author" }) { @message.author }
        time(datetime: @message.display_time_iso) { @message.display_time }
      end

      div(class: "chat-bubble message-body max-w-[min(42rem,78vw)] whitespace-pre-wrap rounded-md bg-base-200 text-base-content shadow-none", data: { testid: "message-body" }) do
        @message.body
      end
    end
  end
end
