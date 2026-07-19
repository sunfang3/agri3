# frozen_string_literal: true

class Views::AdminApp::Sessions::New < Views::Base
  def initialize(login: AdminLogin.new, alert: nil)
    @login = login
    @alert = alert
  end

  def view_template
    div(class: "mx-auto max-w-md px-4 py-10") do
      div(class: "card bg-base-100 shadow") do
        div(class: "card-body") do
          h1(class: "card-title") { "区县管理员登录" }
          render Components::Ui::FlashBanner.new(alert: @alert)

          Form(model: @login, url: admin_login_path, method: :post, scope: false, class: "flex flex-col gap-3") do |f|
            f.field :email, label: "邮箱", required: true
            f.field :password, label: "密码", required: true
            f.submit(:secondary) { "登录" }
          end
        end
      end
    end
  end
end
