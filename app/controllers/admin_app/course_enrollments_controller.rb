# frozen_string_literal: true

module AdminApp
  # Nested under courses: manage students enrolled in a course.
  class CourseEnrollmentsController < AdminApp::BaseController
    before_action :set_course
    before_action :require_manageable_course!
    before_action :set_enrollment, only: %i[update destroy]

    def create
      student = find_student_for_add
      unless student
        return redirect_to admin_course_path(@course), alert: "未找到学员（请检查手机号或从列表选择）"
      end

      enrollment = @course.enrollments.find_or_initialize_by(student: student)
      unless enrollment.new_record?
        return redirect_to admin_course_path(@course), alert: "该学员已在本课程中（#{enrollment.status_label}）"
      end

      desired = params[:status].presence_in(Enrollment::STATUSES) || "enrolled"
      enrollment.status = desired == "enrolled" ? "pending" : desired
      enrollment.save!

      if desired == "enrolled"
        enrollment.confirm!
      elsif desired == "pending"
        AppMessage.create!(
          student: student,
          title: "管理员已为您报名",
          body: "管理员已为您提交课程「#{@course.title}」（#{@course.ownership_label}）报名，待审核录取。",
          message_type: "enrollment"
        )
      end

      track_admin_action!("course_enrollment_create", {
        course_id: @course.id, student_id: student.id, status: enrollment.reload.status
      })
      redirect_to admin_course_path(@course), notice: "#{student.name} 已加入课程（#{enrollment.status_label}）"
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_course_path(@course), alert: e.record.errors.full_messages.to_sentence
    rescue ArgumentError => e
      redirect_to admin_course_path(@course), alert: e.message
    end

    def update
      new_status = params[:status].to_s
      case new_status
      when "enrolled"
        if @enrollment.status == "pending"
          @enrollment.confirm!
        elsif @enrollment.status != "enrolled"
          @enrollment.update!(status: "enrolled", confirmed_at: Time.current)
          notify_status!(@enrollment, "已录取")
        end
      when "dropped"
        if @enrollment.can_transition_to?(:dropped)
          @enrollment.drop!
          notify_status!(@enrollment, "已取消")
        elsif @enrollment.status != "dropped"
          @enrollment.update!(status: "dropped")
          notify_status!(@enrollment, "已取消")
        end
      when "completed"
        if @enrollment.can_transition_to?(:completed)
          @enrollment.complete!
          notify_status!(@enrollment, "已结业")
        end
      when "pending"
        @enrollment.update!(status: "pending", confirmed_at: nil)
      else
        return redirect_to admin_course_path(@course), alert: "无效状态"
      end

      track_admin_action!("course_enrollment_update", {
        course_id: @course.id, enrollment_id: @enrollment.id, status: @enrollment.status
      })
      redirect_to admin_course_path(@course), notice: "#{@enrollment.student.name} → #{@enrollment.reload.status_label}"
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_course_path(@course), alert: e.record.errors.full_messages.to_sentence
    rescue ArgumentError => e
      redirect_to admin_course_path(@course), alert: e.message
    end

    def destroy
      name = @enrollment.student.name
      @enrollment.destroy!
      track_admin_action!("course_enrollment_destroy", { course_id: @course.id, name: name })
      redirect_to admin_course_path(@course), notice: "已移除学员 #{name}"
    end

    private

    def set_course
      @course = current_admin.scoped_courses.find(params[:course_id])
    end

    def set_enrollment
      @enrollment = @course.enrollments.find(params[:id])
    end

    def require_manageable_course!
      return if current_admin.can_manage_course?(@course)

      redirect_to admin_course_path(@course), alert: "无权管理该课程下的学员"
    end

    def find_student_for_add
      if params[:student_id].present?
        current_admin.scoped_students.find_by(id: params[:student_id])
      elsif params[:phone].present?
        phone = params[:phone].to_s.gsub(/\D/, "")
        current_admin.scoped_students.find_by(phone: phone)
      end
    end

    def notify_status!(enrollment, label)
      AppMessage.create!(
        student: enrollment.student,
        title: "报名状态更新",
        body: "课程「#{enrollment.course.title}」状态已更新为：#{label}。",
        message_type: "enrollment"
      )
    end
  end
end
