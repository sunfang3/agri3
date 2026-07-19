# frozen_string_literal: true

module StudentAuthenticatable
  extend ActiveSupport::Concern

  included do
    helper_method :current_student if respond_to?(:helper_method)
  end

  private

  def current_student
    return @current_student if defined?(@current_student)

    @current_student = Student.find_by(id: session[:student_id])
  end

  def require_student!
    return if current_student

    redirect_to student_login_path, alert: "请先登录"
  end

  def track_page!(page)
    AnalyticsEvent.track!(
      event_type: "page_view",
      actor: current_student,
      page: page,
      district_code: current_student&.district&.code
    )
  end

  def track_action!(name, payload = {})
    AnalyticsEvent.track!(
      event_type: "key_action",
      actor: current_student,
      action_name: name,
      payload: payload,
      district_code: current_student&.district&.code
    )
  end
end
