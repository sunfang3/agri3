# frozen_string_literal: true

module AdminApp
  class EnrollmentsController < AdminApp::BaseController
    def bulk_confirm
      ids = Array(params[:enrollment_ids]).map(&:to_i)
      scope = current_admin.scoped_enrollments.where(id: ids)
      confirmed = Enrollment.bulk_confirm!(scope.pluck(:id))
      track_admin_action!("bulk_confirm", { count: confirmed.size })
      redirect_to admin_root_path, notice: "已确认 #{confirmed.size} 条报名"
    end
  end
end
