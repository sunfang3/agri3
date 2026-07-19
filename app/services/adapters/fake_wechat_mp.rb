# frozen_string_literal: true

module Adapters
  class FakeWechatMp
    def send_message(to:, title:, body:, template_key: nil, payload: {})
      { ok: true, provider: "fake_wechat_mp", to: to, template_key: template_key, title: title }
    end
  end
end
