# frozen_string_literal: true

module Adapters
  class FakeLlm
    def structure(transcript)
      {
        "summary" => transcript.to_s[0, 80],
        "topics" => transcript.to_s.scan(/种植|贷款|补贴|培训/).uniq,
        "action_items" => [ "跟进贷款补贴政策" ],
        "sentiment" => "positive"
      }
    end
  end
end
