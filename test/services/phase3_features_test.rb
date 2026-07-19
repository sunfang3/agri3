# frozen_string_literal: true

require "test_helper"

class Phase3FeaturesTest < ActiveSupport::TestCase
  setup do
    District.seed_jinan!
    @district = District.find_by!(code: "licheng")
    @student = Student.create!(
      phone: "133#{rand(10_000_000..99_999_999)}",
      name: "P3",
      district: @district,
      scale: 200,
      annual_income: 600_000
    )
  end

  test "jinan has all official districts (10 区 + 2 县)" do
    District.seed_jinan!
    assert_equal 12, District::JINAN_DISTRICTS.size
    assert_equal %w[district district district district district district district district district district county county],
                 District::JINAN_DISTRICTS.map { |d| d[:kind] }
    District::JINAN_CODES.each do |code|
      d = District.find_by!(code: code)
      assert d.active?
      assert_equal District.meta_for(code)[:name], d.name
    end
    # 非正式功能区不得出现在官方清单
    refute District::JINAN_CODES.include?("gaoxin")
  end


  test "gap analyzer creates policy gap when students exist and zero published policies" do
    # Deterministic fixture: isolate supply so analyzer must emit a policy gap
    Policy.update_all(published: false)
    Course.update_all(published: false)

    isolated = District.create!(name: "缺口测试区", code: "gap-#{SecureRandom.hex(3)}", active: true)
    Student.create!(
      phone: "133#{rand(10_000_000..99_999_999)}",
      name: "缺口学员",
      district: isolated,
      password: "secret"
    )

    gaps = Analytics::GapAnalyzer.new.analyze!
    policy_gaps = gaps.select { |g| g.gap_type == "policy" && g.district_id == isolated.id }
    assert_operator policy_gaps.size, :>=, 1
    gap = policy_gaps.first
    assert_equal "policy", gap.gap_type
    assert_operator gap.demand_count, :>=, 1
    assert_equal 0, gap.supply_count

    Analytics::GapAnalyzer.new.raise_alerts!
    assert Alert.exists?(source_type: "ResourceGap", source_id: gap.id, status: "open")
  end

  test "attribution computes contribution from matches" do
    policy = Policy.create!(title: "归因政策", published: true)
    ResourceMatch.create!(student: @student, matchable: policy, score: 80, status: "recommended", engine: "rules")
    course = Course.create!(title: "归因课", published: true)
    ResourceMatch.create!(student: @student, matchable: course, score: 20, status: "recommended", engine: "rules")

    records = Analytics::AttributionService.new.attribute!(@student, outcome_type: "income_up")
    assert records.size >= 2
    assert_in_delta 1.0, records.sum { |r| r.contribution.to_f }, 0.02
  end

  test "knowledge full text search finds article" do
    KnowledgeArticle.create!(title: "玉米密植", body: "玉米合理密植提高产量与通风", published: true)
    results = KnowledgeArticle.full_text_search("玉米")
    assert results.any? { |a| a.title.include?("玉米") }
  end

  test "showcase contribution score ordering" do
    ShowcaseCase.create!(student: @student, district: @district, title: "低分", contribution_score: 10, published: true)
    ShowcaseCase.create!(student: @student, district: @district, title: "高分", contribution_score: 99, published: true)
    assert_equal "高分", ShowcaseCase.published.first.title
  end

  test "mentor voice answer path" do
    mentor = Mentor.create!(name: "语音导师", district: @district)
    answer = MentorAnswer.create!(student: @student, mentor: mentor, question: "如何防治蚜虫？", status: "open")
    transcript = Adapters::FakeAsr.new.transcribe("q")
    answer.update!(audio_key: "a1", answer_text: transcript, status: "answered")
    assert_equal "answered", answer.status
    assert answer.answer_text.present?
  end
end
