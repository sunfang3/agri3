# frozen_string_literal: true

admins.defaults password: "password", role: "district"
students.defaults password: "password"
policies.defaults published: true, parse_status: "manual"
courses.defaults published: true
surveys.defaults active: true

# create(unique_by:) maintains declared reference values; keep reuses mutable
# demo records without resetting passwords, reviews or learner corrections.
[
  admins, students, mentors, policies, courses, surveys, knowledge_articles,
  showcase_cases, tips_stage_rules, match_weights, enrollments, student_needs,
  honors, capability_assessments, policy_interactions, voice_notes,
  training_photos, check_ins, mentor_answers, attributions, app_messages,
  survey_responses, resource_gaps, alerts
].each do |store|
  store.define_singleton_method(:keep) do |label = nil, unique_by:, **attributes|
    attributes = attributes_for(**attributes)
    record = type.find_by(attributes.slice(*Array(unique_by)))
    if record
      self.label(**{ label => record }) if label
      record
    else
      create(label, **attributes)
    end
  end
end

def demo_multiplier
  Integer(ENV.fetch("SEED_MULTIPLIER", "8"), 10).tap do |count|
    raise ArgumentError, "SEED_MULTIPLIER must be positive" unless count.positive?
  end
end

def demo_reference_date
  value = Student.find_by(phone: "13800000001")&.profile&.fetch("demo_reference_date", nil)
  value.present? ? Date.iso8601(value) : Date.current
end

def demo_label(prefix, index) = :"#{prefix}_#{format('%03d', index)}"
def demo_topic(batch) = %w[基础培育 设施升级 数字经营 品牌建设 绿色防控 成本管理 产销对接 示范带动][batch % 8]
def demo_suffix(batch) = batch.zero? ? "" : "（#{demo_topic(batch)}·第#{batch + 1}期）"
def demo_students = (0...(24 * demo_multiplier)).map { |index| students.public_send(demo_label(:student, index)) }
def demo_course(batch, index) = courses.public_send(demo_label(:course, batch * COURSE_SPECS.size + index))
def demo_policy(batch, index) = policies.public_send(demo_label(:policy, batch * 9 + index))
