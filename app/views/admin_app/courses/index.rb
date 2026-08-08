# frozen_string_literal: true

class Views::AdminApp::Courses::Index < Views::Base
  def initialize(courses: [], enrollment_counts: {}, city_admin: false, manageable_ids: [])
    @courses = courses
    @enrollment_counts = enrollment_counts
    @city_admin = city_admin
    @manageable_ids = manageable_ids.map(&:to_i)
  end

  def view_template
    div(class: "mx-auto max-w-4xl px-4 py-8 space-y-4") do
      div(class: "flex flex-wrap justify-between items-center gap-2") do
        h1(class: "text-xl font-bold") { @city_admin ? "课程管理（全市）" : "课程管理（本区办班）" }
        a(href: new_admin_course_path, class: "btn btn-primary btn-sm") { "新建课程" }
      end
      p(class: "text-xs opacity-60") do
        if @city_admin
          "市直班可完整管理学员；区办班可查看详情（学员由开班区管理）。"
        else
          "仅展示本区开办班级。市直班请在工作台「知会/备案」处理辖区学员。"
        end
      end

      if @courses.any?
        div(class: "overflow-x-auto") do
          table(class: "table table-sm bg-base-100 shadow") do
            thead do
              tr { %w[课程 归属 地点 时间 报名 操作].each { |h| th { h } } }
            end
            tbody do
              @courses.each do |c|
                tr do
                  td do
                    a(href: admin_course_path(c), class: "link link-hover font-medium") { c.title }
                  end
                  td { span(class: "badge badge-ghost badge-sm") { c.ownership_label } }
                  td(class: "text-xs") { c.place.to_s }
                  td(class: "text-xs") { c.starts_on_label }
                  td { (@enrollment_counts[c.id] || 0).to_s }
                  td(class: "space-x-1") do
                    a(href: admin_course_path(c), class: "btn btn-ghost btn-xs") { "学员" }
                    if @manageable_ids.include?(c.id)
                      a(href: edit_admin_course_path(c), class: "btn btn-ghost btn-xs") { "编辑" }
                    end
                  end
                end
              end
            end
          end
        end
      else
        p(class: "text-sm opacity-60") { "暂无课程" }
      end

      a(href: admin_root_path, class: "btn btn-ghost") { "返回后台" }
    end
  end
end
