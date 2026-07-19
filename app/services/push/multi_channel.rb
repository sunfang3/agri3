# frozen_string_literal: true

module Push
  class MultiChannel
    def initialize(
      sms: Adapters::FakeSms.new,
      webpush: Adapters::FakeWebpush.new,
      wechat: Adapters::FakeWechatMp.new
    )
      @adapters = { "sms" => sms, "webpush" => webpush, "wechat_mp" => wechat }
    end

    def deliver!(student:, channel:, title:, body:, template_key: nil, payload: {})
      channel = channel.to_s
      raise ArgumentError, "unknown channel #{channel}" unless @adapters.key?(channel)

      delivery = PushDelivery.create!(
        student: student,
        channel: channel,
        title: title,
        body: body,
        template_key: template_key,
        payload: payload,
        status: "queued"
      )

      result = @adapters[channel].send_message(
        to: student.phone,
        title: title,
        body: body,
        template_key: template_key,
        payload: payload
      )

      delivery.update!(status: result[:ok] ? "sent" : "failed", sent_at: Time.current, payload: payload.merge(result: result))
      delivery
    end
  end
end
