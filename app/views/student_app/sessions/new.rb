# frozen_string_literal: true

class Views::StudentApp::Sessions::New < Views::Base
  def initialize(login: StudentLogin.new, alert: nil)
    @login = login
    @alert = alert
  end

  def view_template
    div(class: "mx-auto max-w-md px-4 py-10") do
      div(class: "card bg-base-100 shadow") do
        div(class: "card-body") do
          h1(class: "card-title") { "学员登录" }
          render Components::Ui::FlashBanner.new(alert: @alert)

          # scope: false → bare phone/password params (controller contract)
          Form(model: @login, url: student_login_path, method: :post, scope: false, class: "flex flex-col gap-3") do |f|
            f.field :phone, label: "手机号", required: true
            f.field :password, label: "密码", required: true
            f.submit(:primary) { "登录" }
          end

          p(class: "text-sm") do
            a(href: student_register_path, class: "link") { "没有账号？注册" }
          end
        end
      end
    end
  end
end
