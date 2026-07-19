# frozen_string_literal: true

module Extractors
  class FakePdfExtractor
    def extract(source)
      if source.respond_to?(:read)
        source.read.to_s
      elsif source.is_a?(String) && File.file?(source)
        File.read(source)
      else
        "政策标题：#{source}\n适用对象：家庭农场\n有效期至 2027-12-31\n内容：补贴示范培训"
      end
    end
  end
end
