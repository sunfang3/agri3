# frozen_string_literal: true

module Matching
  # Writes ResourceMatch rows for all students (T+1 batch) or one student (realtime).
  class Runner
    def self.run_all!(engine: :rules)
      Student.find_each { |s| new(s, engine: engine).run! }
    end

    def initialize(student, engine: :rules)
      @student = student
      @engine_name = engine.to_sym
      @engine = build_engine
    end

    def run!
      resources = Policy.published.valid_now.includes(:tags) + Course.published.includes(:tags)
      resources.each { |resource| upsert_match(resource) }
    end

    def match_one(resource)
      attrs = @engine.build_match(resource)
      upsert_from_attrs(attrs)
    end

    private

    def build_engine
      case @engine_name
      when :cosine then CosineEngine.new(@student)
      else RuleEngine.new(@student)
      end
    end

    def upsert_match(resource)
      upsert_from_attrs(@engine.build_match(resource))
    end

    def upsert_from_attrs(attrs)
      match = ResourceMatch.find_or_initialize_by(
        student: attrs[:student],
        matchable_type: attrs[:matchable].class.name,
        matchable_id: attrs[:matchable].id
      )
      match.assign_attributes(
        score: attrs[:score],
        status: attrs[:status],
        engine: attrs[:engine],
        reason_tags: attrs[:reason_tags] || [],
        cosine_similarity: attrs[:cosine_similarity]
      )
      match.save!
      match
    end
  end
end
