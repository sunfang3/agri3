# frozen_string_literal: true

require "test_helper"

class EnrollmentAckAndReadonlyTest < ActionDispatch::IntegrationTest
  setup do
    @district = District.create!(name: "集成区", code: "ia-#{SecureRandom.hex(3)}")
    @district_admin = Admin.create!(
      name: "区管",
      email: "ia-da-#{SecureRandom.hex(3)}@test.local",
      password: "password",
      role: "district",
      district: @district
    )
    @city_admin = Admin.create!(
      name: "市管",
      email: "ia-ca-#{SecureRandom.hex(3)}@test.local",
      password: "password",
      role: "city"
    )
    @student = Student.create!(
      phone: "133#{rand(10_000_000..99_999_999)}",
      name: "集成学员",
      district: @district,
      password: "secret"
    )
    @city_course = Course.create!(title: "集成市直班", published: true, district: nil)
    @district_course = Course.create!(title: "集成区办班", published: true, district: @district)
    @e_city = Enrollment.create!(student: @student, course: @city_course, status: "pending")
    @e_dist = Enrollment.create!(student: @student, course: @district_course, status: "pending")
  end

  test "district admin bulk acks city-direct without admitting" do
    post admin_login_path, params: { email: @district_admin.email, password: "password" }
    follow_redirect!
    assert_response :success
    assert_select "[data-testid='pending-district-acks']"
    assert_match(/知会|备案/, response.body)

    post admin_bulk_ack_enrollments_path, params: { enrollment_ids: [ @e_city.id ] }
    assert_redirected_to admin_root_path
    assert_equal "acked", @e_city.reload.district_ack_status
    assert_equal "pending", @e_city.status

    # Cannot admit city-direct via bulk_confirm
    post admin_bulk_confirm_enrollments_path, params: { enrollment_ids: [ @e_city.id ] }
    assert_equal "pending", @e_city.reload.status
  end

  test "city admin admits city-direct and sees district courses readonly" do
    post admin_login_path, params: { email: @city_admin.email, password: "password" }
    follow_redirect!
    assert_response :success
    assert_select "[data-testid='district-courses-readonly']"
    assert_match(/区办班报名（只读）/, response.body)
    assert_match(@district_course.title, response.body)

    post admin_bulk_confirm_enrollments_path, params: { enrollment_ids: [ @e_city.id, @e_dist.id ] }
    assert_equal "enrolled", @e_city.reload.status
    assert_equal "pending", @e_dist.reload.status, "区办班市级不可录取"
  end
end
