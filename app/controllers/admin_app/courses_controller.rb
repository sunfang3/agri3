# frozen_string_literal: true

module AdminApp
  class CoursesController < AdminApp::BaseController
    def index
      render Views::AdminApp::Courses::Index.new(courses: Course.order(starts_at: :desc))
    end

    def new
      render Views::AdminApp::Courses::New.new(
        course: Course.new,
        tags: Tag.order(:category, :name),
        mentors: Mentor.order(:name)
      )
    end

    def create
      course = Course.new(course_params)
      if course.save
        tag_ids = Array(params.dig(:course, :tag_ids) || params[:tag_ids]).map(&:to_i).reject(&:zero?)
        course.tag_ids = tag_ids if tag_ids.any?
        track_admin_action!("course_create", { id: course.id })
        redirect_to admin_courses_path, notice: "课程已创建"
      else
        render Views::AdminApp::Courses::New.new(
          course:,
          tags: Tag.order(:category, :name),
          mentors: Mentor.order(:name)
        ), status: :unprocessable_entity
      end
    end

    private

    def course_params
      params.require(:course).permit(
        :title, :description, :mentor_name, :mentor_id, :starts_at, :ends_at,
        :place, :latitude, :longitude, :district_id, :published, tag_ids: []
      )
    end
  end
end
