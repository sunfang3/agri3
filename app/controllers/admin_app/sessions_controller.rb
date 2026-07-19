# frozen_string_literal: true

module AdminApp
  class SessionsController < ApplicationController
    def new
      render Views::AdminApp::Sessions::New.new(login: AdminLogin.new)
    end

    def create
      login = AdminLogin.new(email: params[:email], password: params[:password])
      admin = ::Admin.find_by(email: login.email.to_s.downcase)
      if admin&.authenticate(login.password.to_s)
        session[:admin_id] = admin.id
        AnalyticsEvent.track!(event_type: "login", actor: admin, page: "admin/login", district_code: admin.district&.code)
        redirect_to admin_root_path, notice: "管理员登录成功"
      else
        render Views::AdminApp::Sessions::New.new(login:, alert: "邮箱或密码错误"), status: :unprocessable_entity
      end
    end

    def destroy
      session.delete(:admin_id)
      redirect_to admin_login_path
    end
  end
end

