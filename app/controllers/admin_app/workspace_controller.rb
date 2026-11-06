module AdminApp
  class WorkspaceController < BaseController
    def students
      scope = current_admin.scoped_students.includes(:district, :tags)
      if params[:q].present?
        q = "%#{Student.sanitize_sql_like(params[:q].to_s)}%"
        scope = scope.where("students.name LIKE ? OR phone LIKE ?", q, q)
      end
      scope = scope.where(tips_stage: params[:stage]) if params[:stage].present?
      scope = scope.where(district_id: params[:district_id]) if params[:district_id].present?
      scope = scope.joins(:student_tags).where(student_tags: { tag_id: params[:tag_id] }) if params[:tag_id].present?
      scope = scope.joins(:enrollments).where(enrollments: { status: params[:enrollment_status] }) if params[:enrollment_status].present?
      render Views::AdminApp::Workspace.new(admin: current_admin, page: :students, students: scope.distinct, filter: params.permit(:q, :stage, :district_id, :tag_id, :enrollment_status).to_h)
    end

    def student
      render Views::AdminApp::Workspace.new(admin: current_admin, page: :student, student: current_admin.scoped_students.find(params[:id]))
    end

    def cockpit
      render Views::AdminApp::Workspace.new(admin: current_admin, page: :cockpit)
    end

    def resources
      render Views::AdminApp::Workspace.new(admin: current_admin, page: :resources, query: params[:q].to_s)
    end

    def matching
      if current_admin.city_admin?
        DailyMatchingJob.perform_later(params[:engine].in?(%w[rules cosine]) ? params[:engine] : "rules")
      else
        current_admin.scoped_students.find_each { |student| Matching::Runner.new(student).run! }
      end
      track_admin_action!("refresh_matching")
      redirect_to admin_cockpit_path, notice: "匹配任务已提交"
    end

    def respond_need
      need = StudentNeed.where(student: current_admin.scoped_students).find(params[:id])
      if need.update(params.require(:student_need).permit(:status, :response))
        AppMessage.create!(student: need.student, title: "需求跟进", body: need.response) if need.response.present?
        redirect_to admin_student_path(need.student), notice: "需求跟进已保存"
      else
        redirect_to admin_student_path(need.student), alert: need.errors.full_messages.join("；")
      end
    end

    def review_honor
      honor = Honor.where(student: current_admin.scoped_students).find(params[:id])
      honor.update!(status: params[:status]) if params[:status].in?(%w[approved rejected])
      redirect_to admin_student_path(honor.student), notice: "荣誉审核已保存"
    end

    def review_application
      interaction = PolicyInteraction.where(student: current_admin.scoped_students).find(params[:id])
      if interaction.application_status == "applied" && params[:status].in?(%w[approved rejected])
        interaction.update!(application_status: params[:status])
        AppMessage.create!(student: interaction.student, title: "政策申报进度更新", body: "#{interaction.policy.title}：#{interaction.status_label}")
      end
      redirect_to admin_student_path(interaction.student), notice: "申报进度已保存"
    end

    def assess
      student = current_admin.scoped_students.find(params[:id])
      raw = params.require(:assessment).permit(:assessed_on, scores: CapabilityAssessment::DIMENSIONS.keys)
      assessment = student.capability_assessments.new(assessed_on: raw[:assessed_on], scores: raw.fetch(:scores, {}).to_h.transform_values { |v| Float(v, exception: false) })
      if assessment.save
        redirect_to admin_student_path(student), notice: "能力评估已记录"
      else
        redirect_to admin_student_path(student), alert: assessment.errors.full_messages.join("；")
      end
    end

    def review_showcase
      showcase = ShowcaseCase.where(student: current_admin.scoped_students).find(params[:id])
      showcase.update!(published: params[:published] == "1")
      redirect_to admin_student_path(showcase.student), notice: "作品展示状态已更新"
    end

    def answer_question
      answer = MentorAnswer.where(student: current_admin.scoped_students).find(params[:id])
      if params[:answer_text].present?
        answer.update!(answer_text: params[:answer_text].to_s.first(5000), status: "answered")
        AppMessage.create!(student: answer.student, title: "您的问题收到答复", body: answer.answer_text)
      end
      redirect_to admin_student_path(answer.student), notice: "答疑已保存"
    end

    def create_tag
      return head :forbidden unless current_admin.city_admin?

      tag = Tag.new(params.require(:tag).permit(:name, :category))
      redirect_to admin_resources_path, **(tag.save ? { notice: "标签已创建" } : { alert: tag.errors.full_messages.join("；") })
    end

    def update_tag
      return head :forbidden unless current_admin.city_admin?

      tag = Tag.find(params[:id])
      result = tag.update(params.require(:tag).permit(:name))
      redirect_to admin_resources_path, **(result ? { notice: "标签已更新" } : { alert: tag.errors.full_messages.join("；") })
    end
  end
end
