# frozen_string_literal: true

module StudentApp
  class EnrollmentsController < ApplicationController
    include StudentAuthenticatable
    before_action :require_student!

    def create
      course = Course.published.find(params[:course_id])
      enrollment = current_student.enrollments.find_or_initialize_by(course: course)
      if enrollment.new_record?
        enrollment.status = "pending"
        enrollment.save!
        track_action!("enroll", { course_id: course.id })
        AppMessage.create!(
          student: current_student,
          title: "报名已提交",
          body: "课程「#{course.title}」待管理员审核"
        )
      end
      redirect_to student_home_path, notice: "报名已提交，等待审核"
    end
  end
end
