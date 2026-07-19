# frozen_string_literal: true

require "test_helper"

class Matching::RuleEngineTest < ActiveSupport::TestCase
  setup do
    @district = District.create!(name: "市中区", code: "test-sz-#{SecureRandom.hex(3)}")
    @student = Student.create!(phone: "137#{rand(10_000_000..99_999_999)}", name: "匹配学员", district: @district)
    @t1 = Tag.create!(name: "粮油-#{SecureRandom.hex(2)}", category: "industry")
    @t2 = Tag.create!(name: "家庭农场-#{SecureRandom.hex(2)}", category: "applicable_object")
    @t3 = Tag.create!(name: "规模50-#{SecureRandom.hex(2)}", category: "scale_threshold")
    @student.tags = [ @t1, @t2 ]
    @policy = Policy.create!(title: "补贴政策", content_text: "内容", published: true)
    @policy.tags = [ @t1, @t2, @t3 ]
  end

  test "score is intersection over required tags times 100" do
    engine = Matching::RuleEngine.new(@student, feedback_boost: false)
    # 2 of 3 tags match => 67
    score = engine.score_for(@policy)
    assert_equal 67, score
    assert_includes 0..100, score
  end

  test "full match scores 100" do
    @student.tags = [ @t1, @t2, @t3 ]
    engine = Matching::RuleEngine.new(@student, feedback_boost: false)
    assert_equal 100, engine.score_for(@policy)
  end

  test "no tags scores 0" do
    @student.tags = []
    engine = Matching::RuleEngine.new(@student, feedback_boost: false)
    assert_equal 0, engine.score_for(@policy)
  end

  test "runner persists resource_matches with score and status" do
    Matching::Runner.new(@student, engine: :rules).run!
    match = ResourceMatch.find_by!(student: @student, matchable: @policy)
    assert_includes 0..100, match.score
    assert_includes ResourceMatch::STATUSES, match.status
    assert_equal "rules", match.engine
  end
end
