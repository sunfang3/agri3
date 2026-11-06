# frozen_string_literal: true

module AdminApp
  class CoursesController < AdminApp::BaseController
    before_action :set_course, only: %i[show edit update]
    before_action :require_manageable_course!, only: %i[edit update]

    def index
      courses = current_admin.scoped_courses.includes(:district, :mentor).order(starts_at: :desc, id: :desc)
      enrollment_counts = Enrollment.where(course_id: courses.map(&:id)).group(:course_id).count
      render Views::AdminApp::Courses::Index.new(
        courses: courses,
        enrollment_counts: enrollment_counts,
        city_admin: current_admin.city_admin?,
        manageable_ids: courses.select { |c| current_admin.can_manage_course?(c) }.map(&:id)
      )
    end

    def show
      enrollments = @course.enrollments.includes(student: :district).order(created_at: :desc)
      enrollments = enrollments.where(status: params[:status]) if params[:status].present?
      render Views::AdminApp::Courses::Show.new(
        course: @course,
        enrollments: enrollments,
        manageable: current_admin.can_manage_course?(@course),
        city_admin: current_admin.city_admin?,
        students_for_add: current_admin.scoped_students.order(:name).limit(500),
        status_filter: params[:status]
      )
    end

    def new
      course = Course.new
      course.district_id = current_admin.district_id unless current_admin.city_admin?
      render Views::AdminApp::Courses::New.new(
        course: course,
        tags: Tag.order(:category, :name),
        mentors: Mentor.order(:name),
        city_admin: current_admin.city_admin?
      )
    end

    def create
      course = Course.new(course_params)
      course.district_id = current_admin.district_id unless current_admin.city_admin?
      if course.save
        assign_tags!(course)
        track_admin_action!("course_create", { id: course.id, city_direct: course.city_direct? })
        redirect_to admin_course_path(course), notice: "课程已创建"
      else
        render Views::AdminApp::Courses::New.new(
          course: course,
          tags: Tag.order(:category, :name),
          mentors: Mentor.order(:name),
          city_admin: current_admin.city_admin?
        ), status: :unprocessable_entity
      end
    end

    def edit
      render Views::AdminApp::Courses::Edit.new(
        course: @course,
        tags: Tag.order(:category, :name),
        mentors: Mentor.order(:name),
        city_admin: current_admin.city_admin?
      )
    end

    def update
      if @course.update(course_params_for_update)
        assign_tags!(@course)
        track_admin_action!("course_update", { id: @course.id })
        redirect_to admin_course_path(@course), notice: "课程已更新"
      else
        render Views::AdminApp::Courses::Edit.new(
          course: @course,
          tags: Tag.order(:category, :name),
          mentors: Mentor.order(:name),
          city_admin: current_admin.city_admin?
        ), status: :unprocessable_entity
      end
    end

    private

    def set_course
      @course = current_admin.scoped_courses.find(params[:id])
    end

    def require_manageable_course!
      return if current_admin.can_manage_course?(@course)

      redirect_to admin_course_path(@course), alert: "无权编辑该课程（区办班由开班区管理，市直班由市级管理）"
    end

    def assign_tags!(course)
      tag_ids = Array(params.dig(:course, :tag_ids) || params[:tag_ids]).map(&:to_i).reject(&:zero?)
      course.tag_ids = tag_ids
    end

    def course_params
      params.require(:course).permit(
        :title, :description, :mentor_name, :mentor_id, :starts_at, :ends_at,
        :place, :capacity, :latitude, :longitude, :district_id, :published, tag_ids: []
      )
    end

    def course_params_for_update
      permitted = course_params
      permitted = permitted.except(:district_id) unless current_admin.city_admin?
      permitted
    end
  end
end
