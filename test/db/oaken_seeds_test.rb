require "test_helper"

class OakenSeedsTest < ActiveSupport::TestCase
  include Oaken::Seeds

  DATASETS = [ :data, :districts, :resources, "cases/enrollments", "cases/profiles", "cases/learning", "cases/conversions" ].freeze

  setup { seed_small_demo }

  test "named records describe the two-level enrollment scenario" do
    assert_equal "licheng", students.zhang_san.district.code
    assert_equal "市中区", students.li_si.district.name
    assert_equal students.zhang_san, enrollments.zhang_city.student
    assert courses.city_demonstration.city_direct?
    assert_equal courses.licheng_wheat, enrollments.li_cross_district.course
    assert_equal "pending", enrollments.zhang_city.district_ack_status
    assert_equal "not_required", enrollments.zhang_local.district_ack_status
    assert_equal 24, Student.count
    assert_equal 9, Policy.count
    assert_equal 11, Course.count
    assert_equal 13, Admin.count
    assert_equal 144, CapabilityAssessment.count
  end

  test "repeat loading preserves identity and reviewed or user-maintained data" do
    models = [ Student, Policy, Course, Mentor, Honor, StudentNeed, CapabilityAssessment,
      Enrollment, PolicyInteraction, ShowcaseCase, TrainingPhoto, VoiceNote, ActiveStorage::Blob, ActiveStorage::Attachment ]
    before = models.to_h { |model| [ model, model.count ] }
    student = students.zhang_san
    student.update!(password: "updated-password", primary_industry: "学员自填产业")
    student.tags.clear
    need = student_needs.need_008
    need.update!(status: "responded", response: "人工回复请保留")
    honors.honor_008.update!(status: "rejected")
    enrollments.zhang_local.confirm!
    courses.licheng_wheat.update!(capacity: 90)
    policies.policy_000.update!(issuing_authority: "人工校对单位", parse_status: "approved")
    seed_small_demo
    assert_equal before, models.to_h { |model| [ model, model.count ] }
    assert_equal student.id, students.zhang_san.id
    assert students.zhang_san.authenticate("updated-password")
    assert_equal "学员自填产业", students.zhang_san.primary_industry
    assert_empty students.zhang_san.tags
    assert_equal "人工回复请保留", student_needs.need_008.response
    assert_equal "rejected", honors.honor_008.status
    assert_equal "enrolled", enrollments.zhang_local.status
    assert_equal 90, courses.licheng_wheat.capacity
    assert_equal "人工校对单位", policies.policy_000.issuing_authority
  end

  test "reference data is maintained while file loading can be selected" do
    district = districts.licheng
    district.update!(name: "旧区划名")
    counts = [ Student.count, Policy.count, Course.count ]
    seed :data
    assert_equal "历城区", districts.licheng.name
    assert_equal counts, [ Student.count, Policy.count, Course.count ]
    assert_equal 12, District.jinan_active.count
  end

  test "bulk seed matching uses the domain score including feedback and stays idempotent" do
    FeedbackSignal.create!(student: students.zhang_san, matchable: policies.policy_000, signal_type: "useful", weight: 1)
    expected = Matching::RuleEngine.new(students.zhang_san).build_match(policies.policy_000)
    seed_small_matching
    match = students.zhang_san.resource_matches.find_by!(matchable: policies.policy_000)
    assert_equal expected[:score], match.score
    assert_equal expected[:reason_tags], match.reason_tags
    assert_equal "rules", match.engine
    count = ResourceMatch.count
    seed_small_matching
    assert_equal count, ResourceMatch.count
  end

  private

  def seed_small_demo
    previous = ENV["SEED_MULTIPLIER"]
    ENV["SEED_MULTIPLIER"] = "1"
    seed(*DATASETS)
  ensure
    ENV["SEED_MULTIPLIER"] = previous
  end

  def seed_small_matching
    previous = ENV["SEED_MULTIPLIER"]
    ENV["SEED_MULTIPLIER"] = "1"
    seed "cases/matching"
  ensure
    ENV["SEED_MULTIPLIER"] = previous
  end
end
