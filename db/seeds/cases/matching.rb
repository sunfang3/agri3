# frozen_string_literal: true

# The eightfold dataset has 30,720 matches. Keep the domain engine as the source
# of scores, but preload resource tags and batch the idempotent persistence.
resources = Policy.published.valid_now.includes(:tags).to_a + Course.published.includes(:tags).to_a
evaluator = Tips::StageEvaluator.new
ActiveRecord::Base.logger.silence(Logger::WARN) do
  demo_students.each do |student|
    evaluator.apply!(student)
    engine = Matching::RuleEngine.new(student)
    rows = resources.map do |resource|
      match = engine.build_match(resource)
      { student_id: student.id, matchable_type: resource.class.name, matchable_id: resource.id,
        score: match[:score], status: match[:status], engine: match[:engine],
        reason_tags: match[:reason_tags], cosine_similarity: nil }
    end
    ResourceMatch.upsert_all(rows, unique_by: :idx_resource_matches_unique) if rows.any?
  end
end
KnowledgeArticle.rebuild_search_index!
