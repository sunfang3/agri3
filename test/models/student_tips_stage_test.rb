# frozen_string_literal: true

require "test_helper"

class StudentTipsStageTest < ActiveSupport::TestCase
  test "chinese labels cover all four stages for grassroots UI" do
    assert_equal %w[起步期 成长期 壮大期 示范期],
                 Student::TIPS_STAGES.map { |c| Student.tips_stage_label(c) }

    Student::TIPS_STAGES.each do |code|
      assert Student.tips_stage_hint(code).present?
      assert_includes Student.tips_stage_options.map(&:last), code
      assert_includes Student.tips_stage_options.map(&:first), Student.tips_stage_label(code)
    end
  end

  test "instance helpers reflect stored code" do
    district = District.create!(name: "阶段区", code: "st-#{SecureRandom.hex(3)}")
    student = Student.create!(
      phone: "130#{rand(10_000_000..99_999_999)}",
      name: "测试",
      district: district,
      tips_stage: "P",
      password: "secret"
    )
    assert_equal "壮大期", student.tips_stage_label
    assert_match(/规模扩大/, student.tips_stage_hint)
  end
end
