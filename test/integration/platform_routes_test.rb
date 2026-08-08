# frozen_string_literal: true

require "test_helper"

class PlatformRoutesTest < ActionDispatch::IntegrationTest
  setup do
    @district = District.create!(name: "路由区", code: "rt-#{SecureRandom.hex(3)}")
    @student = Student.create!(phone: "131#{rand(10_000_000..99_999_999)}", name: "路由学员", district: @district, password: "secret")
    @admin = Admin.create!(name: "管", email: "admin-#{SecureRandom.hex(3)}@test.local", password: "password", role: "district", district: @district)
    # 区办班：归属本区，由区县管理员审核
    @course = Course.create!(title: "路由课", published: true, mentor_name: "M", place: "校", district: @district)
  end

  test "root is user entry portal" do
    get root_path
    assert_response :success
    assert_match(/齐鲁农创客/, response.body)
    assert_match(/学员入口/, response.body)
    assert_match(/管理员入口/, response.body)
    assert_select "a[href='#{student_login_path}']"
    assert_select "a[href='#{admin_login_path}']"
    assert_select "[data-testid='nickname-gate']", count: 0
  end

  test "student login home me and enroll flow" do
    post student_login_path, params: { phone: @student.phone, password: "secret" }
    assert_redirected_to student_home_path
    follow_redirect!
    assert_response :success
    assert_match(/推荐清单|首页/, response.body)

    get student_me_path
    assert_response :success
    assert_match(/成长阶段|起步期|成长期|壮大期|示范期|我的/, response.body)

    assert_difference -> { Enrollment.count }, 1 do
      post student_enrollments_path, params: { course_id: @course.id }
    end
    assert AnalyticsEvent.where(event_type: "login", actor: @student).exists?
  end

  test "admin dashboard filter and bulk confirm and csv" do
    enrollment = Enrollment.create!(student: @student, course: @course, status: "pending")
    tag = Tag.create!(name: "筛标签-#{SecureRandom.hex(2)}", category: "industry")
    @student.tags = [ tag ]

    post admin_login_path, params: { email: @admin.email, password: "password" }
    assert_redirected_to admin_root_path
    follow_redirect!
    assert_response :success
    assert_match(/区县汇总|本区学员|学员/, response.body)

    post admin_bulk_confirm_enrollments_path, params: { enrollment_ids: [ enrollment.id ] }
    assert_equal "enrolled", enrollment.reload.status

    get admin_export_students_path
    assert_response :success
    assert_match(/phone/, response.body)
    assert_match(@student.phone, response.body)
  end

  test "health endpoint" do
    get rails_health_check_path
    assert_response :success
  end

  test "avo mount responds" do
    get "/avo"
    assert_includes [ 200, 302 ], response.status
  end

  test "no chat or pgbus product routes" do
    get "/chat"; assert_response :not_found
    get "/stream"; assert_response :not_found
  end
end
