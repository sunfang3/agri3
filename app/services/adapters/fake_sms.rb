# frozen_string_literal: true

module Adapters
  class FakeSms
    def send_message(to:, title:, body:, template_key: nil, payload: {})
      { ok: true, provider: "fake_sms", to: to, body: body }
    end
  end
end
