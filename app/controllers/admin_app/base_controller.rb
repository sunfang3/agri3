# frozen_string_literal: true

module AdminApp
  class BaseController < ApplicationController
    before_action :require_admin!
    helper_method :current_admin

    private

    def current_admin
      @current_admin ||= ::Admin.find_by(id: session[:admin_id])
    end

    def require_admin!
      return if current_admin

      redirect_to admin_login_path, alert: "请先登录管理后台"
    end

    def track_admin_action!(name, payload = {})
      AnalyticsEvent.track!(
        event_type: "key_action",
        actor: current_admin,
        action_name: name,
        payload: payload,
        district_code: current_admin.district&.code
      )
    end
  end
end
