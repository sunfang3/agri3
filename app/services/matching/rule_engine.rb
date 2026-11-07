# frozen_string_literal: true

module Matching
  # Rule-based match: (tag intersection / required tags) * 100, optionally reweighted by MatchWeight + feedback.
  class RuleEngine
    def initialize(student, weights: nil, feedback_boost: true)
      @student = student
      @student_tag_ids = student.tags.pluck(:id).to_set
      @weights = weights
      @feedback_boost = feedback_boost
    end

    def score_for(resource)
      required = resource.tags.to_a
      return 0 if required.empty?
      return 0 if @student_tag_ids.empty?

      intersection = required.count { |t| @student_tag_ids.include?(t.id) }
      base = ((intersection.to_f / required.size) * 100).round

      if @weights
        weighted_num = 0.0
        weighted_den = 0.0
        required.each do |tag|
          w = @weights[tag.category] || MatchWeight.weight_for(tag.category)
          weighted_den += w
          weighted_num += w if @student_tag_ids.include?(tag.id)
        end
        base = weighted_den.positive? ? ((weighted_num / weighted_den) * 100).round : base
      end

      base = apply_feedback_boost(resource, base) if @feedback_boost
      base.clamp(0, 100)
    end

    def match_status(score)
      case score
      when 1..100 then "recommended"
      else "dismissed"
      end
    end

    def build_match(resource)
      score = score_for(resource)
      {
        student: @student,
        matchable: resource,
        score: score,
        status: match_status(score),
        engine: "rules",
        reason_tags: resource.tags.select { |t| @student_tag_ids.include?(t.id) }.map(&:name)
      }
    end

    private

    def apply_feedback_boost(resource, score)
      signals = FeedbackSignal.where(matchable: resource)
      return score if signals.empty?

      useful = signals.where(signal_type: %w[useful applied completed]).sum { |s| s.weight.to_f }
      not_useful = signals.where(signal_type: "not_useful").sum { |s| s.weight.to_f }
      delta = ((useful - not_useful) * 2).round
      (score + delta).clamp(0, 100)
    end
  end
end
