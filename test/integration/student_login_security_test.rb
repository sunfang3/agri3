# frozen_string_literal: true

require "test_helper"

class StudentLoginSecurityTest < ActionDispatch::IntegrationTest
  setup do
    @district = District.create!(name: "登录区", code: "lg-#{SecureRandom.hex(3)}")
  end

  test "rejects login when password_digest is blank regardless of submitted password" do
    student = Student.new(phone: "131#{rand(10_000_000..99_999_999)}", name: "无密码", district: @district)
    student.save!(validate: false)
    student.update_column(:password_digest, nil)

    post student_login_path, params: { phone: student.phone, password: "anything" }
    assert_response :unprocessable_entity
    assert_nil session[:student_id]
  end

  test "rejects wrong password when digest is set" do
    student = Student.create!(
      phone: "131#{rand(10_000_000..99_999_999)}",
      name: "有密码",
      district: @district,
      password: "correct-horse"
    )
    post student_login_path, params: { phone: student.phone, password: "wrong" }
    assert_response :unprocessable_entity
    assert_nil session[:student_id]
  end

  test "accepts correct password" do
    student = Student.create!(
      phone: "131#{rand(10_000_000..99_999_999)}",
      name: "正常",
      district: @district,
      password: "correct-horse"
    )
    post student_login_path, params: { phone: student.phone, password: "correct-horse" }
    assert_redirected_to student_home_path
    assert_equal student.id, session[:student_id]
  end
end
