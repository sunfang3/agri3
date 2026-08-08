# frozen_string_literal: true

class Views::Pages::Home < Views::Base
  def initialize(districts_count: 0, students_count: 0, policies_count: 0, courses_count: 0)
    @districts_count = districts_count
    @students_count = students_count
    @policies_count = policies_count
    @courses_count = courses_count
  end

  def view_template
    div(class: "min-h-dvh bg-gradient-to-b from-primary/10 via-base-200/40 to-base-200") do
      div(class: "mx-auto max-w-4xl px-4 py-10 sm:py-16 space-y-10") do
        header(class: "text-center space-y-3") do
          p(class: "text-sm font-medium text-primary tracking-wide") { "济南市农广校内部平台" }
          h1(class: "text-3xl sm:text-4xl font-bold text-base-content") { "齐鲁农创客全过程管理系统" }
          p(class: "text-base-content/70 max-w-2xl mx-auto") do
            "请选择您的身份进入：学员查看专属适配清单与选课；区县/市级管理员处理报名、导入与汇总。"
          end
        end

        div(class: "grid gap-4 sm:grid-cols-2") do
          render_student_card
          render_admin_card
        end

        render_stats
        render_footer
      end
    end
  end

  private

  def render_student_card
    section(class: "card bg-base-100 shadow-lg border border-primary/20") do
      div(class: "card-body gap-3") do
        h2(class: "card-title text-xl") do
          span(class: "badge badge-primary badge-sm") { "学员" }
          plain "学员入口"
        end
        p(class: "text-sm text-base-content/70") { "注册/登录后进入双 Tab：首页推荐清单与选课，我的画像与标签修正。" }
        ul(class: "text-sm space-y-1 opacity-80 list-disc list-inside") do
          li { "专属政策 / 课程匹配" }
          li { "报名与 App 内消息" }
          li { "学情调查与知识库" }
        end
        div(class: "card-actions justify-end mt-2 flex-wrap gap-2") do
          a(href: student_login_path, class: "btn btn-primary", data: { testid: "entry-student-login" }) { "登录" }
          a(href: student_register_path, class: "btn btn-outline btn-primary", data: { testid: "entry-student-register" }) { "注册" }
        end
      end
    end
  end

  def render_admin_card
    section(class: "card bg-base-100 shadow-lg border border-secondary/20") do
      div(class: "card-body gap-3") do
        h2(class: "card-title text-xl") do
          span(class: "badge badge-secondary badge-sm") { "管理" }
          plain "管理员入口"
        end
        p(class: "text-sm text-base-content/70") { "区县管理员处理本区学员与报名审核；市级账号可看全市驾驶舱。" }
        ul(class: "text-sm space-y-1 opacity-80 list-disc list-inside") do
          li { "学员筛选 / 批量确认报名" }
          li { "Excel 导入与 CSV 导出" }
          li { "政策、课程与学情调查" }
        end
        div(class: "card-actions justify-end mt-2 flex-wrap gap-2") do
          a(href: admin_login_path, class: "btn btn-secondary", data: { testid: "entry-admin-login" }) { "管理后台登录" }
          a(href: "/avo", class: "btn btn-ghost btn-sm") { "Avo 资源管理" }
        end
      end
    end
  end

  def render_stats
    section(class: "card bg-base-100/80 shadow") do
      div(class: "card-body py-4") do
        h3(class: "font-semibold text-sm opacity-70 mb-2") { "平台概况" }
        div(class: "stats stats-vertical sm:stats-horizontal shadow w-full bg-base-200/50") do
          stat("区县", @districts_count, primary: true)
          stat("学员", @students_count)
          stat("政策", @policies_count)
          stat("课程", @courses_count)
        end
      end
    end
  end

  def stat(title, value, primary: false)
    div(class: "stat py-3") do
      div(class: "stat-title") { title }
      div(class: "stat-value text-2xl#{" text-primary" if primary}") { value.to_s }
    end
  end

  def render_footer
    footer(class: "text-center text-xs text-base-content/50 space-y-1") do
      p do
        plain "交流大厅："
        a(href: chat_path, class: "link link-hover", data: { testid: "entry-chat" }) { "/chat" }
        plain " · Litecable 实时（游客昵称 / 已登录用系统姓名）"
      end
      p do
        plain "健康检查："
        a(href: rails_health_check_path, class: "link link-hover") { "/up" }
      end
    end
  end
end

