# frozen_string_literal: true

# T+1 matching job — scheduled via Litejob (cron/timer scheduled).
# config/recurring.yml passes positional args: ["rules"] → perform("rules").
# Also accepts keyword form: perform(engine: "cosine").
class DailyMatchingJob < ApplicationJob
  queue_as :default

  def perform(engine = "rules", **kwargs)
    engine = kwargs[:engine] if kwargs.key?(:engine)
    engine = engine.presence || "rules"

    Tips::StageEvaluator.new.tap do |evaluator|
      Student.find_each { |s| evaluator.apply!(s) }
    end
    Matching::Runner.run_all!(engine: engine.to_sym)
  end
end
