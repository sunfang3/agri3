# frozen_string_literal: true

module Matching
  # Realtime cosine similarity over tag category dimensions + numeric features.
  class CosineEngine
    FEATURE_KEYS = %w[
      industry scale_threshold income_threshold applicable_object course other
      scale_norm income_norm
    ].freeze

    def initialize(student)
      @student = student
      @student_vector = vector_for_student(student)
    end

    def score_for(resource)
      score_from_similarity(similarity(resource), resource)
    end

    def similarity(resource)
      cosine(@student_vector, vector_for_resource(resource))
    end

    def build_match(resource)
      sim = similarity(resource)
      score = score_from_similarity(sim, resource)
      {
        student: @student,
        matchable: resource,
        score: score,
        status: score.positive? ? "recommended" : "dismissed",
        engine: "cosine",
        cosine_similarity: sim.round(6),
        reason_tags: resource.tags.map(&:name)
      }
    end

    # Non-negative mapping: sim≤0 or empty resource tags => 0; sim=1 => 100.
    # Avoids ((sim+1)/2*100) which maps orthogonal/empty overlap to 50.
    def self.score_from_similarity(sim, resource_tag_count: nil)
      return 0 if resource_tag_count == 0
      return 0 if sim.nil? || sim <= 0

      (sim * 100).round.clamp(0, 100)
    end

    # Pure unit for tests: vectors as hashes of feature => float
    def self.cosine_similarity(a, b)
      keys = (a.keys | b.keys)
      return 0.0 if keys.empty?

      dot = keys.sum { |k| a.fetch(k, 0.0) * b.fetch(k, 0.0) }
      na = Math.sqrt(keys.sum { |k| a.fetch(k, 0.0)**2 })
      nb = Math.sqrt(keys.sum { |k| b.fetch(k, 0.0)**2 })
      return 0.0 if na.zero? || nb.zero?

      dot / (na * nb)
    end

    private

    def score_from_similarity(sim, resource)
      self.class.score_from_similarity(sim, resource_tag_count: resource.tags.size)
    end

    def cosine(a, b)
      self.class.cosine_similarity(a, b)
    end

    def vector_for_student(student)
      vec = Hash.new(0.0)
      student.tags.each do |tag|
        vec[tag.category] += 1.0
        vec["tag:#{tag.id}"] = 1.0
      end
      vec["scale_norm"] = normalize_scale(student.scale)
      vec["income_norm"] = normalize_income(student.annual_income)
      vec
    end

    def vector_for_resource(resource)
      vec = Hash.new(0.0)
      resource.tags.each do |tag|
        vec[tag.category] += 1.0
        vec["tag:#{tag.id}"] = 1.0
      end
      vec
    end

    def normalize_scale(scale)
      [ scale.to_f / 500.0, 1.0 ].min
    end

    def normalize_income(income)
      [ income.to_f / 1_000_000.0, 1.0 ].min
    end
  end
end
