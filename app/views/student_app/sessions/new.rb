class Views::StudentApp::Sessions::New < Views::WorkspaceBase
  def initialize(login: StudentLogin.new, alert: nil)
    @login, @alert = login, alert
  end

  def view_template
    div(class: "card auth-card") do
      chip("我的培育空间", "y")
      h1 { "学员登录" }
      p(class: "muted") { "欢迎回来，查看属于您的政策与课程。" }
      render Components::Ui::FlashBanner.new(alert: @alert)
      Form(url: student_login_path, method: :post, scope: false, class: "form-stack mt") do
        text_field("phone", "手机号", value: @login.phone, type: "tel", required: true, autocomplete: "username")
        text_field("password", "密码", type: "password", required: true, autocomplete: "current-password")
        button(type: "submit", class: "tbtn pri") { "登录培育空间 →" }
      end
      div(class: "actions mt") { action("注册新账号", student_register_path); action("管理员登录", admin_login_path) }
    end
  end
end
