# frozen_string_literal: true

require "test_helper"

class SeedSmokeTest < ActiveSupport::TestCase
  test "District.seed_jinan creates 12 active official districts" do
    count = District.seed_jinan!
    assert_equal 12, count
    assert_equal 12, District.jinan_active.count
    assert Admin.create!(
      name: "seed admin",
      email: "seed-admin-#{SecureRandom.hex(3)}@test.local",
      password: "password",
      role: "city"
    ).persisted?
  end

  test "rule matching produces resource_matches for tagged student" do
    district = District.create!(name: "匹配区", code: "match-#{SecureRandom.hex(3)}")
    student = Student.create!(phone: "136#{rand(10_000_000..99_999_999)}", name: "S", district: district)
    t1 = Tag.create!(name: "t-#{SecureRandom.hex(2)}", category: "industry")
    student.tags = [ t1 ]
    policy = Policy.create!(title: "P", content_text: "x", published: true)
    policy.tags = [ t1 ]
    Matching::Runner.new(student, engine: :rules).run!
    match = ResourceMatch.find_by!(student: student, matchable: policy)
    assert_equal 100, match.score
    assert_equal "rules", match.engine
  end
end
