# frozen_string_literal: true

module Adapters
  class FakeWebpush
    def send_message(to:, title:, body:, template_key: nil, payload: {})
      { ok: true, provider: "fake_webpush", to: to, title: title }
    end
  end
end
