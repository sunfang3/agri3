# frozen_string_literal: true

class Views::StudentApp::Home::Show < Views::Base
  TIERS = [
    [ 1, "强烈推荐", "border-error" ],
    [ 2, "建议关注", "border-warning" ],
    [ 3, "可了解", "border-base-300" ]
  ].freeze

  def initialize(tier1: [], tier2: [], tier3: [], courses: [], enrollments_by_course: {}, unread_count: 0)
    @tiers = { 1 => tier1, 2 => tier2, 3 => tier3 }
    @courses = courses
    @enrollments_by_course = enrollments_by_course
    @unread_count = unread_count.to_i
  end

  def view_template
    div(class: "mx-auto max-w-lg min-h-dvh bg-base-100 flex flex-col pb-20") do
      header(class: "navbar bg-primary text-primary-content px-4") do
        div(class: "flex-1 font-semibold") { "首页 · 专属适配清单" }
        div(class: "flex-none flex items-center gap-1") do
          a(href: student_messages_path, class: "btn btn-ghost btn-sm relative") do
            plain "消息"
            if @unread_count.positive?
              span(class: "badge badge-error badge-sm absolute -top-1 -right-1", data: { testid: "message-badge" }) { @unread_count.to_s }
            end
          end
        end
      end


      section(class: "p-4 space-y-4 flex-1") do
        div do
          h2(class: "font-bold text-lg mb-2") { "推荐清单" }
          TIERS.each do |tier, label, border|
            render_tier(tier, label, @tiers[tier], border)
          end
        end

        div do
          h2(class: "font-bold text-lg mb-2") { "选课入口" }
          ul(class: "space-y-2") do
            @courses.each { |course| render_course_row(course) }
          end
        end
      end

      render Components::Student::BottomNav.new(active: :home)
    end
  end

  private

  def render_tier(tier, label, items, border)
    div(class: "mb-3", data: { priority_tier: tier }) do
      div(class: "text-sm font-medium opacity-70 mb-1") { label }
      if items.blank?
        p(class: "text-xs opacity-50") { "暂无" }
      else
        ul(class: "space-y-2") do
          items.each do |m|
            li(class: "card card-bordered border-l-4 #{border} bg-base-200/40") do
              div(class: "card-body p-3 gap-1") do
                div(class: "font-medium") { m.matchable.try(:title).to_s }
                div(class: "text-xs opacity-70") { "#{m.matchable_type} · 匹配度 #{m.score}" }
              end
            end
          end
        end
      end
    end
  end

  def render_course_row(course)
    enrollment = @enrollments_by_course[course.id]
    li(class: "flex items-center justify-between gap-2 rounded-lg bg-base-200 p-3") do
      div do
        div(class: "font-medium") { course.title }
        div(class: "text-xs opacity-70") do
          plain "#{course.ownership_label} · #{course.mentor_display} · #{course.place}"
        end
      end
      if enrollment
        span(
          class: "badge #{enrollment.status == "enrolled" ? "badge-success" : "badge-ghost"} badge-sm",
          data: { testid: "enrollment-status-#{course.id}" }
        ) { enrollment.status_label }
      else
        button_to "报名", student_enrollments_path(course_id: course.id), method: :post, class: "btn btn-sm btn-primary"
      end
    end
  end
end
