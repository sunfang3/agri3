# frozen_string_literal: true

require "test_helper"

class EnrollmentTest < ActiveSupport::TestCase
  setup do
    @district = District.create!(name: "历城区", code: "test-licheng-#{SecureRandom.hex(3)}")
    @student = Student.create!(phone: "139#{rand(10_000_000..99_999_999)}", name: "测试学员", district: @district)
    @course = Course.create!(title: "测试课程", published: true)
    @enrollment = Enrollment.create!(student: @student, course: @course, status: "pending")
  end

  test "pending can transition to enrolled and completed" do
    assert @enrollment.can_transition_to?(:enrolled)
    assert_difference -> { AppMessage.where(student: @student).count }, 1 do
      @enrollment.confirm!
    end
    assert_equal "enrolled", @enrollment.status
    assert @enrollment.confirmed_at.present?
    msg = AppMessage.where(student: @student, title: "报名已通过").last
    assert msg
    assert_includes msg.body, @course.title
    assert_includes msg.body, "已录取"

    @enrollment.complete!
    assert_equal "completed", @enrollment.status
  end

  test "pending can drop" do
    @enrollment.drop!
    assert_equal "dropped", @enrollment.status
    assert_raises(ArgumentError) { @enrollment.confirm! }
  end

  test "bulk_confirm transitions pending only and notifies each student" do
    other_student = Student.create!(phone: "138#{rand(10_000_000..99_999_999)}", name: "B", district: @district)
    other = Enrollment.create!(
      student: other_student,
      course: @course,
      status: "pending"
    )
    assert_difference -> { AppMessage.where(title: "报名已通过").count }, 2 do
      confirmed = Enrollment.bulk_confirm!([ @enrollment.id, other.id ])
      assert_equal 2, confirmed.size
      assert confirmed.all? { |e| e.status == "enrolled" }
    end
  end

  test "invalid transition raises" do
    @enrollment.complete! rescue nil
    @enrollment.update!(status: "completed")
    assert_raises(ArgumentError) { @enrollment.transition_to!("enrolled") }
  end
end
