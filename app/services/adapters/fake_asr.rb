# frozen_string_literal: true

module Adapters
  class FakeAsr
    def transcribe(audio_source)
      "今天学习了小麦种植技术，学员反馈规模扩大到一百亩，需要贷款补贴政策。"
    end
  end
end
