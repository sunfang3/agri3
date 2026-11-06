require "test_helper"

class OakenEnrollmentTest < ActionDispatch::IntegrationTest
  include Oaken::Seeds

  setup do
    previous = ENV["SEED_MULTIPLIER"]
    ENV["SEED_MULTIPLIER"] = "1"
    seed :data, :districts, :resources, "cases/enrollments"
  ensure
    ENV["SEED_MULTIPLIER"] = previous
  end

  test "district admission and city admission reuse the same named scenario" do
    post admin_login_path, params: { email: admins.licheng.email, password: "password" }
    post admin_bulk_confirm_enrollments_path, params: { enrollment_ids: [ enrollments.zhang_local.id, enrollments.zhang_city.id ] }
    assert_equal "enrolled", enrollments.zhang_local.status
    assert_equal "pending", enrollments.zhang_city.status
    post admin_bulk_ack_enrollments_path, params: { enrollment_ids: [ enrollments.zhang_city.id ] }
    assert_equal "acked", enrollments.zhang_city.district_ack_status
    assert_equal "pending", enrollments.zhang_city.status

    post admin_login_path, params: { email: admins.city.email, password: "password" }
    post admin_bulk_confirm_enrollments_path, params: { enrollment_ids: [ enrollments.zhang_city.id ] }
    assert_equal "enrolled", enrollments.zhang_city.status
    assert students.zhang_san.app_messages.exists?(title: "报名已通过")
  end
end
