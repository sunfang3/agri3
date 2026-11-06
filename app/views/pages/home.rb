class Views::Pages::Home < Views::WorkspaceBase
  def initialize(districts_count: 0, students_count: 0, policies_count: 0, courses_count: 0)
    @stats = { "覆盖区县" => districts_count, "在册学员" => students_count, "政策资源" => policies_count, "培训课程" => courses_count }
  end

  def view_template
    section(class: "portal-hero") do
      p(class: "eyebrow") { "JINAN AGRICULTURAL BROADCASTING SCHOOL · 培育服务平台" }
      h1 do
        plain "齐鲁农创客学员全过程管理系统"
        br
        span { "让每一项政策，找到对的人" }
      end
      p { "以学员全息画像与政策资源为双核，将评估、匹配、触达与反馈连接起来，为每一位农创客提供适合自己的培育服务。" }
      div(class: "actions", style: "justify-content:center") { %w[评估 匹配 触达 反馈].each { |label| chip(label) } }
    end
    div(class: "g2 portal-cards") do
      section(class: "card portal-card") do
        chip("我的培育空间", "y")
        h2 { "学员入口" }
        p(class: "muted") { "专属政策清单、选课报名与终身成长档案" }
        ul { [ "精准匹配政策与课程", "在线报名与学习记录", "全息画像与成果展示" ].each { |text| li { "✓　#{text}" } } }
        div(class: "actions") do
          a(href: student_login_path, class: "tbtn pri", data: { testid: "entry-student-login" }) { "学员登录 →" }
          a(href: student_register_path, class: "tbtn", data: { testid: "entry-student-register" }) { "注册新账号" }
        end
      end
      section(class: "card portal-card") do
        chip("市 · 区县协同", "c")
        h2 { "管理员入口" }
        p(class: "muted") { "一站式管理学员、课程、政策与培育过程" }
        ul { [ "学员档案与两级报名审核", "政策资源、标签与课程管理", "全市汇总与精准匹配驾驶舱" ].each { |text| li { "✓　#{text}" } } }
        a(href: admin_login_path, class: "tbtn pri", data: { testid: "entry-admin-login" }) { "进入管理工作台 →" }
      end
    end
    section(class: "portal-stats") { kpis(@stats) }
    footer(class: "muted", style: "text-align:center;margin-top:24px") do
      plain "济南市农业广播电视学校 · 齐鲁农创客培育服务平台　"
      a(href: chat_path, class: "link", data: { testid: "entry-chat" }) { "公共交流大厅 ↗" }
    end
  end
end
