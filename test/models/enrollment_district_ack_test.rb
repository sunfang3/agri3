# frozen_string_literal: true

require "test_helper"

class EnrollmentDistrictAckTest < ActiveSupport::TestCase
  setup do
    @licheng = District.create!(name: "历城备", code: "ack-lc-#{SecureRandom.hex(3)}")
    @shizhong = District.create!(name: "市中备", code: "ack-sz-#{SecureRandom.hex(3)}")
    @district_admin = Admin.create!(
      name: "区备",
      email: "ack-da-#{SecureRandom.hex(3)}@test.local",
      password: "password",
      role: "district",
      district: @licheng
    )
    @other_admin = Admin.create!(
      name: "他区",
      email: "ack-oa-#{SecureRandom.hex(3)}@test.local",
      password: "password",
      role: "district",
      district: @shizhong
    )
    @city_admin = Admin.create!(
      name: "市备",
      email: "ack-ca-#{SecureRandom.hex(3)}@test.local",
      password: "password",
      role: "city"
    )
    @student = Student.create!(
      phone: "132#{rand(10_000_000..99_999_999)}",
      name: "备案学员",
      district: @licheng,
      password: "secret"
    )
    @city_course = Course.create!(title: "市直备案班", published: true, district: nil)
    @district_course = Course.create!(title: "历城区办班", published: true, district: @licheng)
  end

  test "city-direct enrollment defaults to district_ack pending" do
    e = Enrollment.create!(student: @student, course: @city_course, status: "pending")
    assert_equal "pending", e.district_ack_status
    assert e.needs_district_ack?
  end

  test "district course enrollment does not require district ack" do
    e = Enrollment.create!(student: @student, course: @district_course, status: "pending")
    assert_equal "not_required", e.district_ack_status
  end

  test "district admin can ack own students city-direct enrollment" do
    e = Enrollment.create!(student: @student, course: @city_course, status: "pending")
    e.ack_by_district!(@district_admin)
    assert_equal "acked", e.reload.district_ack_status
    assert e.district_acked_at.present?
    assert_equal @district_admin.id, e.district_ack_admin_id
    assert_equal "pending", e.status, "备案不改变录取状态"
  end

  test "other district admin cannot ack" do
    e = Enrollment.create!(student: @student, course: @city_course, status: "pending")
    assert_raises(ArgumentError) { e.ack_by_district!(@other_admin) }
  end

  test "city admin cannot use district ack path" do
    e = Enrollment.create!(student: @student, course: @city_course, status: "pending")
    assert_raises(ArgumentError) { e.ack_by_district!(@city_admin) }
  end

  test "pending_district_acks lists only pending acks for district admin" do
    e = Enrollment.create!(student: @student, course: @city_course, status: "pending")
    ids = @district_admin.pending_district_acks.pluck(:id)
    assert_includes ids, e.id
    e.ack_by_district!(@district_admin)
    refute_includes @district_admin.pending_district_acks.pluck(:id), e.id
  end

  test "city admin readonly sees district courses not city-direct" do
    e_city = Enrollment.create!(student: @student, course: @city_course, status: "pending")
    e_dist = Enrollment.create!(
      student: @student,
      course: @district_course,
      status: "pending"
    )
    ids = @city_admin.scoped_district_courses_readonly.pluck(:id)
    assert_includes ids, e_dist.id
    refute_includes ids, e_city.id
    refute_includes @city_admin.scoped_enrollments.pluck(:id), e_dist.id
  end
end
