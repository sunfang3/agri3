# frozen_string_literal: true

require "test_helper"

class AdminMutationContractTest < ActiveSupport::TestCase
  cover "Admin#city_admin?"
  cover "Admin#can_manage_course?"

  test "course management follows course ownership for every admin role" do
    courses = [ Course.new(district_id: nil), Course.new(district_id: 10), Course.new(district_id: 20) ]
    { "city" => [ true, false, false ], "system" => [ true, false, false ], "district" => [ false, true, false ] }.each do |role, expected|
      admin = Admin.new(role: role, district_id: 10)
      assert_equal role != "district", admin.city_admin?
      courses.zip(expected).each { |course, allowed| assert_equal allowed, admin.can_manage_course?(course) }
    end
  end

  test "district admin without a district cannot manage city courses" do
    assert_equal false, Admin.new(role: "district").can_manage_course?(Course.new)
    assert_equal false, Admin.new(role: "unknown").city_admin?
  end
end

class EnrollmentMutationContractTest < ActiveSupport::TestCase
  cover "Enrollment#can_transition_to?"

  test "only documented enrollment transitions are allowed, including symbol input" do
    expected = {
      "pending" => %w[enrolled dropped],
      "enrolled" => %w[completed dropped],
      "completed" => [],
      "dropped" => [],
      "unknown" => [],
      nil => []
    }
    expected.each do |status, allowed|
      enrollment = Enrollment.new(status: status)
      %w[pending enrolled completed dropped unknown].each do |target|
        assert_equal allowed.include?(target), enrollment.can_transition_to?(target)
        assert_equal allowed.include?(target), enrollment.can_transition_to?(target.to_sym)
      end
      assert_equal false, enrollment.can_transition_to?(nil)
    end
  end
end

class RecommendationMutationContractTest < ActiveSupport::TestCase
  cover "Matching::RuleEngine#match_status"
  cover "ResourceMatch#priority_tier"
  cover "ResourceMatch#priority_label"

  test "positive matching scores are recommended and zero or out of range scores dismissed" do
    engine = Matching::RuleEngine.new(Student.new)
    [ 1, 49, 49.5, 50, 79, 79.5, 80, 100 ].each do |score|
      assert_equal "recommended", engine.match_status(score)
    end
    [ -1, 0, 101 ].each { |score| assert_equal "dismissed", engine.match_status(score) }
  end

  test "recommendation tier and label change at 50 and 80" do
    { nil => 3, -1 => 3, 0 => 3, 1 => 3, 49 => 3, 50 => 2, 79 => 2, 80 => 1, 100 => 1, 101 => 3 }.each do |score, tier|
      match = ResourceMatch.new(score: score)
      assert_equal tier, match.priority_tier
      assert_equal({ 1 => "强烈推荐", 2 => "建议关注", 3 => "可了解" }.fetch(tier), match.priority_label)
    end
  end
end
