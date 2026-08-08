# frozen_string_literal: true

class Views::AdminApp::Dashboard::Show < Views::Base
  def initialize(
    students:,
    tags: [],
    pending_enrollments: [],
    pending_district_acks: [],
    district_courses_readonly: [],
    city_admin: false,
    district_summary:,
    cockpit: nil,
    alerts: [],
    gaps: [],
    cases: [],
    filter: {}
  )
    @students = students
    @tags = tags
    @pending_enrollments = pending_enrollments
    @pending_district_acks = pending_district_acks
    @district_courses_readonly = district_courses_readonly
    @city_admin = city_admin
    @district_summary = district_summary
    @cockpit = cockpit
    @alerts = alerts
    @gaps = gaps
    @cases = cases
    @filter = filter
  end

  def view_template
    div(class: "mx-auto max-w-5xl px-4 py-6 space-y-6") do
      render_toolbar
      render_summary
      render_cockpit if @cockpit
      render_students_filter
      render_bulk_confirm
      render_district_acks unless @city_admin
      render_city_readonly_district_courses if @city_admin
      render_alerts if @alerts.any? || @gaps.any?
      render_cases if @cases.any?
    end
  end

  private

  def render_toolbar
    div(class: "flex flex-wrap items-center justify-between gap-2") do
      h1(class: "text-2xl font-bold") { @city_admin ? "市级管理后台" : "区县管理后台" }
      div(class: "flex flex-wrap gap-2") do
        a(href: new_admin_import_path, class: "btn btn-sm") { "Excel 导入" }
        a(href: admin_policies_path, class: "btn btn-sm") { "政策" }
        a(href: admin_courses_path, class: "btn btn-sm") { "课程" }
        a(href: admin_surveys_path, class: "btn btn-sm") { "学情调查" }
        a(href: admin_export_students_path, class: "btn btn-sm btn-outline") { "CSV 导出学员" }
        a(href: "/avo", class: "btn btn-sm btn-ghost") { "Avo" }
        button_to "退出", admin_logout_path, method: :delete, class: "btn btn-sm btn-ghost"
      end
    end
  end

  def render_summary
    section(class: "card bg-base-100 shadow") do
      div(class: "card-body") do
        h2(class: "card-title text-lg") { @city_admin ? "全市汇总视图" : "区县汇总视图" }
        div(class: "stats stats-vertical lg:stats-horizontal shadow") do
          div(class: "stat") do
            div(class: "stat-title") { @city_admin ? "学员总数" : "本区学员" }
            div(class: "stat-value text-primary") { @district_summary[:total_students].to_s }
          end
          div(class: "stat") do
            div(class: "stat-title") { "成长阶段分布" }
            div(class: "stat-desc text-base") do
              @district_summary[:by_stage].map { |code, n| "#{::Student.tips_stage_label(code)} #{n}人" }.join(" · ")
            end
          end
          div(class: "stat") do
            div(class: "stat-title") { "可审报名状态" }
            div(class: "stat-desc text-base") { @district_summary[:enrollments].map { |k, v| "#{k}:#{v}" }.join(" · ") }
          end
        end
      end
    end
  end

  def render_cockpit
    section(class: "card bg-base-100 shadow") do
      div(class: "card-body") do
        h2(class: "card-title text-lg") { "市级基础驾驶舱" }
        pre(class: "text-xs bg-base-200 p-3 rounded overflow-auto") { JSON.pretty_generate(@cockpit) }
      end
    end
  end

  def render_students_filter
    section(class: "card bg-base-100 shadow") do
      div(class: "card-body") do
        h2(class: "card-title text-lg") { @city_admin ? "学员 · 多维筛选" : "本区学员 · 多维筛选" }

        Form(url: admin_root_path, method: :get, scope: false, class: "flex flex-wrap gap-2 mb-4") do |f|
          select(name: "stage", class: "select select-bordered select-sm", data: { testid: "filter-stage" }) do
            option(value: "") { "全部成长阶段" }
            ::Student.tips_stage_options.each do |label, code|
              option(value: code, selected: @filter[:stage] == code) { label }
            end
          end
          select(name: "tag_id", class: "select select-bordered select-sm", data: { testid: "filter-tag" }) do
            option(value: "") { "全部标签" }
            @tags.each do |tag|
              option(value: tag.id, selected: @filter[:tag_id].to_s == tag.id.to_s) { "#{tag.category}:#{tag.name}" }
            end
          end
          select(name: "enrollment_status", class: "select select-bordered select-sm", data: { testid: "filter-enrollment" }) do
            option(value: "") { "全部报名状态" }
            Enrollment::STATUSES.each do |s|
              option(value: s, selected: @filter[:enrollment_status] == s) { s }
            end
          end
          f.submit(:primary, class: "btn-sm") { "筛选" }
        end

        div(class: "overflow-x-auto") do
          table(class: "table table-sm") do
            thead { tr { %w[姓名 手机 区县 成长阶段 主业].each { |h| th { h } } } }
            tbody do
              @students.limit(100).each do |s|
                tr do
                  td { s.name }
                  td { s.phone }
                  td { s.district.name }
                  td { s.tips_stage_label }
                  td { s.primary_industry.to_s }
                end
              end
            end
          end
        end
      end
    end
  end

  def render_bulk_confirm
    section(class: "card bg-base-100 shadow") do
      div(class: "card-body") do
        h2(class: "card-title text-lg") { "待我审核录取" }
        p(class: "text-xs opacity-60 -mt-2 mb-2") do
          if @city_admin
            "市级录取：仅市直班。区办班见下方「只读」列表，不可在此确认。"
          else
            "区县录取：仅本区开办的班。本区学员报的市直班请到「知会/备案」处理，不可在此录取。"
          end
        end
        Form(url: admin_bulk_confirm_enrollments_path, method: :post, scope: false) do |f|
          ul(class: "space-y-2 mb-3", data: { testid: "pending-enrollments" }) do
            @pending_enrollments.each do |e|
              li(class: "flex items-center gap-2") do
                input(type: "checkbox", name: "enrollment_ids[]", value: e.id, class: "checkbox checkbox-sm", checked: true)
                span(class: "text-sm") do
                  plain "#{e.student.name}（#{e.student.district.name}）→ #{e.course.title} "
                  span(class: "badge badge-ghost badge-sm") { e.course.ownership_label }
                  plain " · #{e.status}"
                end
              end
            end
          end
          if @pending_enrollments.any?
            f.submit(:primary, class: "btn-sm") { "批量确认录取" }
          else
            p(class: "text-sm opacity-60") { "暂无待你审核录取的报名" }
          end
        end
      end
    end
  end

  def render_district_acks
    section(class: "card bg-base-100 shadow border border-info/30") do
      div(class: "card-body") do
        h2(class: "card-title text-lg") { "市直班 · 知会 / 备案" }
        p(class: "text-xs opacity-60 -mt-2 mb-2") do
          "本区学员报名市直班后，市级负责录取；区县仅做知会与备案，不代替市级批准。"
        end
        Form(url: admin_bulk_ack_enrollments_path, method: :post, scope: false) do |f|
          ul(class: "space-y-2 mb-3", data: { testid: "pending-district-acks" }) do
            @pending_district_acks.each do |e|
              li(class: "flex items-center gap-2") do
                input(type: "checkbox", name: "enrollment_ids[]", value: e.id, class: "checkbox checkbox-sm", checked: true)
                span(class: "text-sm") do
                  plain "#{e.student.name} → #{e.course.title} "
                  span(class: "badge badge-info badge-sm") { "市直班" }
                  plain " · 录取状态 #{e.status}"
                end
              end
            end
          end
          if @pending_district_acks.any?
            f.submit(:primary, class: "btn-sm btn-info") { "批量知会/备案" }
          else
            p(class: "text-sm opacity-60") { "暂无待备案的市直班报名" }
          end
        end
      end
    end
  end

  def render_city_readonly_district_courses
    section(class: "card bg-base-100 shadow border border-warning/30") do
      div(class: "card-body") do
        h2(class: "card-title text-lg") { "区办班报名（只读）" }
        p(class: "text-xs opacity-60 -mt-2 mb-2") do
          "各区开办班级的报名由开班区县审核录取。市级可查看，不可在此批量确认。"
        end
        if @district_courses_readonly.any?
          div(class: "overflow-x-auto", data: { testid: "district-courses-readonly" }) do
            table(class: "table table-sm") do
              thead do
                tr { %w[学员 学员区县 课程 开班区 录取状态 区备案].each { |h| th { h } } }
              end
              tbody do
                @district_courses_readonly.each do |e|
                  tr do
                    td { e.student.name }
                    td { e.student.district.name }
                    td { e.course.title }
                    td { e.course.district&.name.to_s }
                    td { e.status }
                    td { e.district_ack_status }
                  end
                end
              end
            end
          end
        else
          p(class: "text-sm opacity-60") { "暂无区办班报名记录" }
        end
      end
    end
  end

  def render_alerts
    section(class: "card bg-base-100 shadow") do
      div(class: "card-body") do
        h2(class: "card-title text-lg") { "预警中心 / 资源缺口" }
        ul(class: "text-sm space-y-1") do
          @alerts.each { |a| li(class: "badge badge-warning badge-outline") { "#{a.severity}: #{a.title}" } }
          @gaps.each { |g| li { "#{g.gap_type} — #{g.title}" } }
        end
      end
    end
  end

  def render_cases
    section(class: "card bg-base-100 shadow") do
      div(class: "card-body") do
        h2(class: "card-title text-lg") { "案例展示墙" }
        ul(class: "space-y-2") do
          @cases.each do |c|
            li(class: "p-2 bg-base-200 rounded") do
              strong { c.title }
              plain " · 贡献分 #{c.contribution_score}"
            end
          end
        end
      end
    end
  end
end
