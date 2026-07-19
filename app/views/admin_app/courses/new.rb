# frozen_string_literal: true

class Views::AdminApp::Courses::New < Views::Base
  def initialize(course:, tags: [], mentors: [])
    @course = course
    @tags = tags
    @mentors = mentors
  end

  def view_template
    div(class: "mx-auto max-w-lg px-4 py-8") do
      h1(class: "text-xl font-bold mb-4") { "新建课程" }
      render CourseForm.new(
        model: @course,
        url: admin_courses_path,
        method: :post,
        tags: @tags,
        mentors: @mentors
      )
    end
  end
end
