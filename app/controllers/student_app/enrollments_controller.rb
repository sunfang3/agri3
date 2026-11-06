# frozen_string_literal: true

module StudentApp
  class EnrollmentsController < ApplicationController
    include StudentAuthenticatable
    before_action :require_student!

    def create
      course = Course.published.find(params[:course_id])
      return redirect_to student_courses_path, alert: "该课程名额已满" if course.full?
      enrollment = current_student.enrollments.find_or_initialize_by(course: course)
      if enrollment.new_record?
        enrollment.status = "pending"
        enrollment.save!
        track_action!("enroll", { course_id: course.id, city_direct: course.city_direct? })
        AppMessage.create!(
          student: current_student,
          title: "报名已提交",
          body: "课程「#{course.title}」（#{course.ownership_label}）待#{course.reviewer_label}审核"
        )
      end
      notice = "报名已提交，等待#{course.reviewer_label}审核"
      redirect_to student_home_path, notice: notice
    end
  end
end
