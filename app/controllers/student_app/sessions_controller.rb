# frozen_string_literal: true

module StudentApp
  class SessionsController < ApplicationController
    include StudentAuthenticatable

    def new
      render Views::StudentApp::Sessions::New.new(login: StudentLogin.new)
    end

    def create
      login = StudentLogin.new(phone: params[:phone], password: params[:password])
      student = ::Student.find_by(phone: login.phone.to_s.gsub(/\D/, ""))
      password = login.password.to_s

      if student&.password_digest.present? && password.present? && student.authenticate(password)
        session[:student_id] = student.id
        AnalyticsEvent.track!(
          event_type: "login",
          actor: student,
          page: "student/login",
          district_code: student.district.code
        )
        redirect_to student_home_path, notice: "登录成功"
      else
        alert = student&.password_digest.blank? ? "账号未设置密码，请联系管理员或重新注册" : "手机号或密码错误"
        render Views::StudentApp::Sessions::New.new(login:, alert:), status: :unprocessable_entity
      end
    end

    def destroy
      session.delete(:student_id)
      redirect_to student_login_path, notice: "已退出"
    end
  end
end
