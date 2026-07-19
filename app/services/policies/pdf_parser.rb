# frozen_string_literal: true

module Policies
  # PDF auto-parse with human review path. Uses adapter for text extraction.
  class PdfParser
    def initialize(extractor: Extractors::FakePdfExtractor.new)
      @extractor = extractor
    end

    def parse(policy, pdf_io_or_path = nil)
      text = if pdf_io_or_path
        @extractor.extract(pdf_io_or_path)
      else
        policy.pdf_text.presence || @extractor.extract(policy.title)
      end

      fields = extract_fields(text)
      policy.update!(
        pdf_text: text,
        parsed_fields: fields,
        parse_status: "pending_review",
        content_text: policy.content_text.presence || text
      )
      policy
    end

    def approve!(policy, overrides: {})
      if overrides.any?
        fields = (policy.parsed_fields || {}).merge(overrides.stringify_keys)
        policy.parsed_fields = fields
        policy.title = overrides[:title] if overrides[:title]
        policy.valid_until = overrides[:valid_until] if overrides[:valid_until]
        policy.content_text = overrides[:content_text] if overrides[:content_text]
      end
      policy.parse_status = "approved"
      policy.save!
      policy
    end

    private

    def extract_fields(text)
      {
        "detected_title" => text.to_s.lines.first.to_s.strip.presence || "未命名政策",
        "valid_until" => text.to_s[/\d{4}[-年]\d{1,2}[-月]\d{1,2}/],
        "keywords" => text.to_s.scan(/补贴|示范|培训|贷款|保险/).uniq
      }
    end
  end
end
