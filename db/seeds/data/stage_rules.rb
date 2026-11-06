# frozen_string_literal: true

RULE_SPECS.each do |spec|
  tips_stage_rules.keep :"stage_#{spec[:stage].downcase}", unique_by: :name, **spec, enabled: true
end

{ "industry" => 1.2, "applicable_object" => 1.0, "scale_threshold" => 0.8,
  "income_threshold" => 0.6, "deadline" => 0.5, "course" => 1.0, "other" => 1.0 }.each do |category, weight|
  match_weights.keep category.to_sym, unique_by: :tag_category, tag_category: category, weight: weight
end
