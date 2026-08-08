# frozen_string_literal: true

class Views::AdminApp::Courses::New < Views::Base
  def initialize(course:, tags: [], mentors: [], city_admin: false)
    @course = course
    @tags = tags
    @mentors = mentors
    @city_admin = city_admin
  end

  def view_template
    div(class: "mx-auto max-w-lg px-4 py-8") do
      h1(class: "text-xl font-bold mb-4") { "新建课程" }
      p(class: "text-xs opacity-60 mb-3") do
        if @city_admin
          "开班归属选空 = 市直班（市级录取）。选区县 = 区办班（由该区管理学员）。"
        else
          "区县账号创建的课程自动归属本区（区办班）。"
        end
      end
      render CourseForm.new(
        model: @course,
        url: admin_courses_path,
        method: :post,
        tags: @tags,
        mentors: @mentors
      )
      a(href: admin_courses_path, class: "btn btn-ghost mt-4") { "返回" }
    end
  end
end
