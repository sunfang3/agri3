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
    @enrollment.confirm!
    assert_equal "enrolled", @enrollment.status
    assert @enrollment.confirmed_at.present?

    @enrollment.complete!
    assert_equal "completed", @enrollment.status
  end

  test "pending can drop" do
    @enrollment.drop!
    assert_equal "dropped", @enrollment.status
    assert_raises(ArgumentError) { @enrollment.confirm! }
  end

  test "bulk_confirm transitions pending only" do
    other = Enrollment.create!(
      student: Student.create!(phone: "138#{rand(10_000_000..99_999_999)}", name: "B", district: @district),
      course: @course,
      status: "pending"
    )
    confirmed = Enrollment.bulk_confirm!([ @enrollment.id, other.id ])
    assert_equal 2, confirmed.size
    assert confirmed.all? { |e| e.status == "enrolled" }
  end

  test "invalid transition raises" do
    @enrollment.complete! rescue nil
    @enrollment.update!(status: "completed")
    assert_raises(ArgumentError) { @enrollment.transition_to!("enrolled") }
  end
end
