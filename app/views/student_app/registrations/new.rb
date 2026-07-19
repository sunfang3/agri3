# frozen_string_literal: true

class Views::StudentApp::Registrations::New < Views::Base
  def initialize(student:)
    @student = student
  end

  def view_template
    div(class: "mx-auto max-w-lg px-4 py-8") do
      div(class: "card bg-base-100 shadow") do
        div(class: "card-body") do
          h1(class: "card-title") { "学员注册 · 基础画像" }
          if @student.errors.any?
            div(class: "alert alert-error text-sm") { @student.errors.full_messages.join(", ") }
          end

          render StudentRegistrationForm.new(
            model: @student,
            url: student_register_path,
            method: :post
          )
        end
      end
    end
  end
end
