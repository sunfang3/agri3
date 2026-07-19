# frozen_string_literal: true

module Analytics
  # 成效归因：回溯匹配贡献度
  class AttributionService
    def attribute!(student, outcome_type:, matchable: nil)
      matches = student.resource_matches.ranked.limit(5)
      total = matches.sum(&:score).to_f
      total = 1.0 if total.zero?

      records = []
      matches.each do |m|
        contrib = (m.score / total).round(3)
        records << Attribution.create!(
          student: student,
          outcome_type: outcome_type,
          matchable: m.matchable,
          contribution: contrib,
          details: { match_score: m.score, engine: m.engine }
        )
      end

      if matchable
        records << Attribution.create!(
          student: student,
          outcome_type: outcome_type,
          matchable: matchable,
          contribution: 1.0,
          details: { direct: true }
        )
      end
      records
    end
  end
end
