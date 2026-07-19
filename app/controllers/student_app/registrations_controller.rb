# frozen_string_literal: true

module StudentApp
  class RegistrationsController < ApplicationController
    include StudentAuthenticatable

    def new
      render Views::StudentApp::Registrations::New.new(student: ::Student.new)
    end

    def create
      student = ::Student.new(student_params)
      if student.save
        session[:student_id] = student.id
        AnalyticsEvent.track!(event_type: "login", actor: student, page: "student/register", district_code: student.district.code)
        AnalyticsEvent.track!(
          event_type: "key_action",
          actor: student,
          action_name: "register",
          payload: { student_id: student.id },
          district_code: student.district&.code
        )
        redirect_to student_home_path, notice: "注册成功"
      else
        render Views::StudentApp::Registrations::New.new(student:), status: :unprocessable_entity
      end
    end

    private

    def student_params
      params.require(:student).permit(
        :phone, :name, :district_id, :primary_industry, :scale, :annual_income, :honors, :password
      )
    end
  end
end
