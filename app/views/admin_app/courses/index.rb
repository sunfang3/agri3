# frozen_string_literal: true

class Views::AdminApp::Courses::Index < Views::Base
  def initialize(courses: [])
    @courses = courses
  end

  def view_template
    div(class: "mx-auto max-w-3xl px-4 py-8 space-y-4") do
      div(class: "flex justify-between") do
        h1(class: "text-xl font-bold") { "课程管理" }
        a(href: new_admin_course_path, class: "btn btn-primary btn-sm") { "新建" }
      end
      ul(class: "space-y-2") do
        @courses.each do |c|
          li(class: "p-3 bg-base-100 rounded shadow-sm") do
            div(class: "font-medium") { c.title }
            div(class: "text-xs opacity-70") { "#{c.mentor_display} · #{c.place} · #{c.starts_at}" }
          end
        end
      end
      a(href: admin_root_path, class: "btn btn-ghost") { "返回" }
    end
  end
end
