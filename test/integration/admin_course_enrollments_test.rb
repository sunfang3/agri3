# frozen_string_literal: true

require "test_helper"

class AdminCourseEnrollmentsTest < ActionDispatch::IntegrationTest
  setup do
    @district = District.create!(name: "课管区", code: "cm-#{SecureRandom.hex(3)}")
    @other = District.create!(name: "他区", code: "cm-o-#{SecureRandom.hex(3)}")
    @district_admin = Admin.create!(
      name: "区课",
      email: "cm-da-#{SecureRandom.hex(3)}@test.local",
      password: "password",
      role: "district",
      district: @district
    )
    @city_admin = Admin.create!(
      name: "市课",
      email: "cm-ca-#{SecureRandom.hex(3)}@test.local",
      password: "password",
      role: "city"
    )
    @student = Student.create!(
      phone: "134#{rand(10_000_000..99_999_999)}",
      name: "课管学员",
      district: @district,
      password: "secret"
    )
    @district_course = Course.create!(title: "区办管理班", published: true, district: @district)
    @city_course = Course.create!(title: "市直管理班", published: true, district: nil)
  end

  test "district admin manages enrollments on own course" do
    post admin_login_path, params: { email: @district_admin.email, password: "password" }

    get admin_course_path(@district_course)
    assert_response :success
    assert_select "[data-testid='course-enrollments']", count: 0 # empty list no table? actually empty shows text
    assert_match(/添加学员/, response.body)

    assert_difference -> { @district_course.enrollments.count }, 1 do
      post admin_course_enrollments_path(@district_course), params: {
        phone: @student.phone,
        status: "enrolled"
      }
    end
    assert_redirected_to admin_course_path(@district_course)
    enrollment = @district_course.enrollments.find_by!(student: @student)
    assert_equal "enrolled", enrollment.status
    assert AppMessage.exists?(student: @student, title: "报名已通过")

    get admin_course_path(@district_course)
    assert_response :success
    assert_select "[data-testid='course-enrollments']"
    assert_match(@student.name, response.body)

    patch admin_course_enrollment_path(@district_course, enrollment), params: { status: "completed" }
    assert_equal "completed", enrollment.reload.status

    assert_difference -> { Enrollment.count }, -1 do
      delete admin_course_enrollment_path(@district_course, enrollment)
    end
  end

  test "district admin cannot manage city-direct course enrollments" do
    post admin_login_path, params: { email: @district_admin.email, password: "password" }
    get admin_courses_path
    assert_response :success
    assert_no_match(/市直管理班/, response.body)

    get admin_course_path(@city_course)
    assert_response :not_found
  end

  test "city admin manages city-direct enrollments and views district course" do
    post admin_login_path, params: { email: @city_admin.email, password: "password" }

    get admin_course_path(@city_course)
    assert_response :success
    assert_match(/添加学员/, response.body)

    post admin_course_enrollments_path(@city_course), params: {
      student_id: @student.id,
      status: "enrolled"
    }
    assert_equal "enrolled", @city_course.enrollments.find_by!(student: @student).status

    get admin_course_path(@district_course)
    assert_response :success
    assert_match(/只读/, response.body)
    assert_no_match(/添加学员/, response.body)
  end
end
