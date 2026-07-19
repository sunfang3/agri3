# frozen_string_literal: true

module Tips
  # Configurable T-I-P-S dynamic stage判定
  class StageEvaluator
    def initialize(rules: nil)
      @rules = rules || TipsStageRule.enabled.to_a
    end

    def evaluate(student)
      rule = @rules.find { |r| r.matches?(student) }
      rule&.stage || fallback_stage(student)
    end

    def apply!(student)
      stage = evaluate(student)
      student.update!(tips_stage: stage) if student.tips_stage != stage
      stage
    end

    private

    def fallback_stage(student)
      scale = student.scale.to_f
      income = student.annual_income.to_f
      if scale >= 200 || income >= 500_000
        "S"
      elsif scale >= 100 || income >= 200_000
        "P"
      elsif scale >= 50 || income >= 80_000
        "I"
      else
        "T"
      end
    end
  end
end
