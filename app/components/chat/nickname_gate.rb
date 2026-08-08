# frozen_string_literal: true

class Components::Chat::NicknameGate < Components::Base
  def initialize(identity: ChatIdentity.new)
    @identity = identity
  end

  def view_template
    section(class: "mx-auto flex min-h-dvh w-full max-w-md items-center px-5 py-10", data: { testid: "nickname-gate" }) do
      div(class: "w-full border-y border-base-300 bg-base-100 px-1 py-8 sm:border sm:px-8") do
        header(class: "space-y-2") do
          div(class: "mb-5 flex size-11 items-center justify-center rounded-md bg-primary text-primary-content") do
            render LucideIcon(:message_square_text, class: "size-5", aria: { hidden: true })
          end
          p(class: "text-sm font-semibold text-primary") { "公共大厅" }
          h1(class: "text-3xl font-bold") { "选择你的昵称" }
          p(class: "text-base-content/65") { "昵称仅保存在当前浏览器会话中。实时通道：Litecable（Action Cable）。" }
        end

        div(class: "mt-7") { render_form }
      end
    end
  end

  private

  def render_form
    Form(model: @identity, url: chat_identity_path, method: :patch, class: "space-y-4") do |form|
      form.field :nickname, label: "昵称", required: true, autofocus: true, autocomplete: "nickname", maxlength: 20
      p(role: "alert", class: "text-sm text-error") { @identity.errors.full_messages.to_sentence } if @identity.errors.any?
      form.submit(:primary, class: "btn-block") { "进入大厅" }
    end
  end
end
