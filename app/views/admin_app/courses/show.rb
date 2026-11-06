# frozen_string_literal: true

class Views::AdminApp::Courses::Show < Views::Base
  def initialize(course:, enrollments: [], manageable: false, city_admin: false, students_for_add: [], status_filter: nil)
    @course = course
    @enrollments = enrollments
    @manageable = manageable
    @city_admin = city_admin
    @students_for_add = students_for_add
    @status_filter = status_filter
  end

  def view_template
    div(class: "mx-auto max-w-4xl px-4 py-8 space-y-6") do
      render_header
      render_meta
      render_add_student if @manageable
      render_enrollments
      a(href: admin_courses_path, class: "btn btn-ghost") { "返回课程列表" }
    end
  end

  private

  def render_header
    div(class: "flex flex-wrap justify-between items-start gap-2") do
      div do
        h1(class: "text-xl font-bold") { @course.title }
        p(class: "text-sm opacity-70 mt-1") do
          span(class: "badge badge-sm mr-1") { @course.ownership_label }
          plain @course.published? ? "已发布" : "未发布"
        end
      end
      div(class: "flex gap-2") do
        if @manageable
          a(href: edit_admin_course_path(@course), class: "btn btn-sm") { "编辑课程" }
          a(href: check_in_code_admin_course_path(@course), class: "btn btn-sm") { "现场签到码" }
        else
          span(class: "badge badge-warning") { "只读（非开班主体）" }
        end
      end
    end
  end

  def render_meta
    section(class: "card bg-base-100 shadow") do
      div(class: "card-body text-sm space-y-1") do
        h2(class: "card-title text-base") { "课程信息" }
        p { plain "导师："; plain @course.mentor_display.to_s }
        p { plain "地点："; plain @course.place.to_s }
        p { plain "时间："; plain @course.time_range_label }
        p { plain "简介："; plain @course.description.to_s.presence || "—" }
        p do
          plain "录取权："
          plain(@course.city_direct? ? "市级管理员" : "#{@course.district&.name}管理员")
        end
      end
    end
  end

  def render_add_student
    section(class: "card bg-base-100 shadow border border-primary/20") do
      div(class: "card-body space-y-3") do
        h2(class: "card-title text-base") { "添加学员" }
        p(class: "text-xs opacity-60 -mt-2") { "可按手机号或从列表选择。默认直接「已录取」并通知学员。" }

        Form(url: admin_course_enrollments_path(@course), method: :post, scope: false, class: "flex flex-col gap-2") do |f|
          div(class: "flex flex-wrap gap-2 items-end") do
            div do
              label(class: "label label-text text-xs") { "手机号" }
              input(type: "text", name: "phone", class: "input input-bordered input-sm", placeholder: "11位手机号", data: { testid: "add-enrollment-phone" })
            end
            div do
              label(class: "label label-text text-xs") { "或选择学员" }
              select(name: "student_id", class: "select select-bordered select-sm max-w-xs", data: { testid: "add-enrollment-student" }) do
                option(value: "") { "— 选择 —" }
                @students_for_add.each do |s|
                  option(value: s.id) { "#{s.name} #{s.phone}（#{s.district.name}）" }
                end
              end
            end
            div do
              label(class: "label label-text text-xs") { "初始状态" }
              select(name: "status", class: "select select-bordered select-sm") do
                option(value: "enrolled", selected: true) { "已录取" }
                option(value: "pending") { "待审核" }
              end
            end
            f.submit(:primary, class: "btn-sm") { "添加" }
          end
        end
      end
    end
  end

  def render_enrollments
    section(class: "card bg-base-100 shadow") do
      div(class: "card-body space-y-3") do
        div(class: "flex flex-wrap justify-between items-center gap-2") do
          h2(class: "card-title text-base") { "课程学员（#{@enrollments.size}）" }
          div(class: "flex flex-wrap gap-1") do
            a(href: admin_course_path(@course), class: "btn btn-xs #{@status_filter.blank? ? "btn-active" : "btn-ghost"}") { "全部" }
            Enrollment::STATUSES.each do |st|
              a(
                href: admin_course_path(@course, status: st),
                class: "btn btn-xs #{@status_filter == st ? "btn-active" : "btn-ghost"}"
              ) { Enrollment.new(status: st).status_label }
            end
          end
        end

        if @enrollments.any?
          div(class: "overflow-x-auto", data: { testid: "course-enrollments" }) do
            table(class: "table table-sm") do
              thead do
                tr { %w[学员 手机 区县 状态 区备案 操作].each { |h| th { h } } }
              end
              tbody do
                @enrollments.each do |e|
                  tr do
                    td { e.student.name }
                    td { e.student.phone }
                    td { e.student.district.name }
                    td { span(class: "badge badge-sm") { e.status_label } }
                    td(class: "text-xs") { e.district_ack_status }
                    td do
                      if @manageable
                        div(class: "flex flex-wrap gap-1") do
                          status_actions(e)
                          form(action: admin_course_enrollment_path(@course, e), method: "post", class: "inline") do
                            input(type: "hidden", name: "_method", value: "delete")
                            input(type: "hidden", name: "authenticity_token", value: view_context.form_authenticity_token)
                            button(type: "submit", class: "btn btn-ghost btn-xs text-error", data: { confirm: "确定移除？" }) { "移除" }
                          end
                        end
                      else
                        span(class: "text-xs opacity-50") { "—" }
                      end
                    end
                  end
                end
              end
            end
          end
        else
          p(class: "text-sm opacity-60") { "暂无学员报名" }
        end
      end
    end
  end

  def status_actions(enrollment)
    case enrollment.status
    when "pending"
      status_button(enrollment, "enrolled", "录取", "btn-success")
      status_button(enrollment, "dropped", "拒绝", "btn-warning")
    when "enrolled"
      status_button(enrollment, "completed", "结业", "btn-info")
      status_button(enrollment, "dropped", "取消", "btn-warning")
    when "dropped"
      status_button(enrollment, "pending", "恢复待审", "btn-ghost")
    end
  end

  def status_button(enrollment, status, label, btn_class)
    form(action: admin_course_enrollment_path(@course, enrollment), method: "post", class: "inline") do
      input(type: "hidden", name: "_method", value: "patch")
      input(type: "hidden", name: "authenticity_token", value: view_context.form_authenticity_token)
      input(type: "hidden", name: "status", value: status)
      button(type: "submit", class: "btn btn-xs #{btn_class}") { label }
    end
  end
end
