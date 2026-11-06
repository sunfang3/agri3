# frozen_string_literal: true

module AdminApp
  class DashboardController < AdminApp::BaseController
    def show
      AnalyticsEvent.track!(event_type: "page_view", actor: current_admin, page: "admin/dashboard", district_code: current_admin.district&.code)
      render Views::AdminApp::Workspace.new(admin: current_admin, page: :dashboard)
    end
  end
end
