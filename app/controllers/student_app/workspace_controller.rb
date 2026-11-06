require "csv"

module StudentApp
  class WorkspaceController < ApplicationController
    include StudentAuthenticatable
    before_action :require_student!

    def achievements
      track_page!("student/achievements")
      render Views::StudentApp::Workspace.new(student: current_student, page: :achievements)
    end

    def report
      rows = [ [ "学员", "区县", "阶段", "已结业课程", "已获批政策", "已审核荣誉" ],
        [ current_student.name, current_student.district.name, current_student.tips_stage_label,
          current_student.enrollments.where(status: "completed").count,
          current_student.policy_interactions.where(application_status: "approved").count,
          current_student.honor_records.where(status: "approved").count ] ]
      send_data "\uFEFF" + CSV.generate { |csv| rows.each { |row| csv << row } }, filename: "achievement.csv", type: "text/csv"
    end

    def create_need
      need = current_student.student_needs.new(params.require(:student_need).permit(:body))
      if need.save
        track_action!("submit_need")
        redirect_to student_me_path, notice: "需求已提交，管理员将为您跟进"
      else
        redirect_to student_me_path, alert: need.errors.full_messages.join("；")
      end
    end

    def create_honor
      honor = current_student.honor_records.new(params.require(:honor).permit(:title, :awarded_on, :evidence))
      if honor.save
        redirect_to student_achievements_path, notice: "荣誉已提交，等待管理员审核"
      else
        redirect_to student_achievements_path, alert: honor.errors.full_messages.join("；")
      end
    end

    def create_showcase
      showcase = current_student.showcase_cases.new(params.require(:showcase).permit(:title, :body, :media))
      showcase.district = current_student.district
      showcase.published = false
      if showcase.save
        redirect_to student_achievements_path, notice: "作品已提交，审核后展示"
      else
        redirect_to student_achievements_path, alert: showcase.errors.full_messages.join("；")
      end
    end

    def create_voice_note
      course = enrolled_courses.find(params[:course_id])
      note = current_student.voice_notes.new(course: course, transcript: params[:transcript], status: "transcribed")
      if params[:audio].present?
        note.audio.attach(params[:audio])
        note.status = "pending"
      end
      if note.audio.attached? || note.transcript.present?
        if note.save
          redirect_to student_course_path(course), notice: "笔记已保存"
        else
          redirect_to student_course_path(course), alert: note.errors.full_messages.join("；")
        end
      else
        redirect_to student_course_path(course), alert: "请填写笔记或选择音频"
      end
    end

    def create_photo
      course = enrolled_courses.find(params[:course_id])
      photo = current_student.training_photos.new(course: course)
      if params[:image].present? && params[:image].content_type.in?(%w[image/jpeg image/png image/webp])
        photo.image.attach(params[:image])
        unless photo.save
          return redirect_to student_course_path(course), alert: photo.errors.full_messages.join("；")
        end
        Photos::WatermarkService.new.attach!(photo, place: course.place)
        redirect_to student_course_path(course), notice: "实操照片已归档"
      else
        redirect_to student_course_path(course), alert: "请选择 JPG、PNG 或 WebP 照片"
      end
    end

    private

    def enrolled_courses
      Course.where(id: current_student.enrollments.where(status: %w[enrolled completed]).select(:course_id))
    end
  end
end
