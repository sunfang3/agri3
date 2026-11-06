class Views::AdminApp::Sessions::New < Views::WorkspaceBase
  def initialize(login: AdminLogin.new, alert: nil)
    @login, @alert = login, alert
  end

  def view_template
    div(class: "card auth-card") do
      chip("市 · 区县协同", "c")
      h1 { "管理员登录" }
      p(class: "muted") { "市级与区县管理员统一入口，按角色分配管理权限。" }
      render Components::Ui::FlashBanner.new(alert: @alert)
      Form(url: admin_login_path, method: :post, scope: false, class: "form-stack mt") do
        text_field("email", "工作邮箱", value: @login.email, type: "email", required: true, autocomplete: "username")
        text_field("password", "密码", type: "password", required: true, autocomplete: "current-password")
        button(type: "submit", class: "tbtn pri") { "进入管理工作台 →" }
      end
      div(class: "actions mt") { action("学员登录", student_login_path); action("返回门户", root_path) }
    end
  end
end
