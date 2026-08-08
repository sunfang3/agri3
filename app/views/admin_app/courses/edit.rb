# frozen_string_literal: true

class Views::AdminApp::Courses::Edit < Views::Base
  def initialize(course:, tags: [], mentors: [], city_admin: false)
    @course = course
    @tags = tags
    @mentors = mentors
    @city_admin = city_admin
  end

  def view_template
    div(class: "mx-auto max-w-lg px-4 py-8") do
      h1(class: "text-xl font-bold mb-4") { "编辑课程" }
      render CourseForm.new(
        model: @course,
        url: admin_course_path(@course),
        method: :patch,
        tags: @tags,
        mentors: @mentors
      )
      a(href: admin_course_path(@course), class: "btn btn-ghost mt-4") { "返回详情" }
    end
  end
end
