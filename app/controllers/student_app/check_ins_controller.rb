# frozen_string_literal: true

module StudentApp
  class CheckInsController < ApplicationController
    include StudentAuthenticatable
    before_action :require_student!

    def create
      course = Course.find(params[:course_id])
      check_in = CheckIns::QrService.new.check_in!(
        student: current_student,
        course: course,
        token: params[:token],
        latitude: params[:latitude],
        longitude: params[:longitude]
      )
      track_action!("check_in", { course_id: course.id, gps_valid: check_in.gps_valid })
      redirect_to student_home_path, notice: check_in.gps_valid ? "签到成功" : "签到已记录（GPS 未通过验证）"
    rescue ArgumentError => e
      redirect_to student_home_path, alert: e.message
    end
  end
end
