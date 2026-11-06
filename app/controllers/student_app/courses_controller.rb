module StudentApp
  class CoursesController < ApplicationController
    include StudentAuthenticatable
    before_action :require_student!

    def index
      track_page!("student/courses")
      courses = Course.published.includes(:district, :mentor, :tags).order(:starts_at)
      if params[:q].present?
        q = "%#{Course.sanitize_sql_like(params[:q].to_s)}%"
        courses = courses.where("title LIKE ? OR mentor_name LIKE ? OR description LIKE ?", q, q, q)
      end
      courses = courses.city_direct if params[:ownership] == "city"
      courses = courses.where.not(district_id: nil) if params[:ownership] == "district"
      if params[:year].to_s.match?(/\A\d{4}\z/)
        courses = courses.where(starts_at: Time.zone.local(params[:year].to_i)...Time.zone.local(params[:year].to_i + 1))
      end
      render Views::StudentApp::Workspace.new(student: current_student, page: :courses, courses: courses, filter: params.permit(:q, :ownership, :year, :archive_q, :month).to_h)
    end

    def show
      course = Course.published.find(params[:id])
      render Views::StudentApp::Workspace.new(student: current_student, page: :course, course: course, filter: params.permit(:token).to_h)
    end
  end
end
