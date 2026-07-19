# frozen_string_literal: true

module Matching
  # Feedback闭环回流：adjust MatchWeight by signal aggregates
  class FeedbackReweighter
    def reweight!
      useful = FeedbackSignal.where(signal_type: %w[useful applied completed]).count
      not_useful = FeedbackSignal.where(signal_type: "not_useful").count
      base = 1.0
      delta = ((useful - not_useful).to_f / [ useful + not_useful, 1 ].max) * 0.5
      weight = (base + delta).clamp(0.2, 3.0)

      Tag::CATEGORIES.each do |category|
        mw = MatchWeight.find_or_initialize_by(tag_category: category)
        mw.weight = weight
        mw.save!
      end
      MatchWeight.all
    end
  end
end
