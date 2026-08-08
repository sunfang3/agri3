# frozen_string_literal: true

module AdminApp
  class EnrollmentsController < AdminApp::BaseController
    def bulk_confirm
      ids = Array(params[:enrollment_ids]).map(&:to_i)
      scope = current_admin.scoped_enrollments.where(id: ids)
      confirmed = Enrollment.bulk_confirm!(scope.pluck(:id))
      track_admin_action!("bulk_confirm", { count: confirmed.size })
      redirect_to admin_root_path, notice: "已确认录取 #{confirmed.size} 条报名"
    end

    # 区县：对本区学员的市直班报名做知会/备案（不改变录取状态）
    def bulk_ack
      unless current_admin.city_admin?
        ids = Array(params[:enrollment_ids]).map(&:to_i)
        scope = current_admin.pending_district_acks.where(id: ids)
        acked = Enrollment.bulk_ack!(scope.pluck(:id), admin: current_admin)
        track_admin_action!("bulk_district_ack", { count: acked.size })
        redirect_to admin_root_path, notice: "已知会/备案 #{acked.size} 条市直班报名"
      else
        redirect_to admin_root_path, alert: "市级账号无需做区备案"
      end
    end
  end
end
