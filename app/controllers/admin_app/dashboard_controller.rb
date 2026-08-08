# frozen_string_literal: true

module AdminApp
  class DashboardController < AdminApp::BaseController
    def show
      AnalyticsEvent.track!(event_type: "page_view", actor: current_admin, page: "admin/dashboard", district_code: current_admin.district&.code)
      students = filter_students(current_admin.scoped_students.includes(:district, :tags, :enrollments))
      render Views::AdminApp::Dashboard::Show.new(
        students:,
        tags: Tag.order(:category, :name),
        pending_enrollments: current_admin.scoped_enrollments.pending.includes(student: :district, course: :district),
        pending_district_acks: current_admin.pending_district_acks.includes(student: :district, course: :district),
        district_courses_readonly: (
          if current_admin.city_admin?
            current_admin.scoped_district_courses_readonly
              .order(created_at: :desc)
              .limit(50)
              .includes(student: :district, course: :district)
          else
            []
          end
        ),
        city_admin: current_admin.city_admin?,
        district_summary: district_summary,
        cockpit: (Dashboard::CityCockpit.new.summary if current_admin.city_admin?),
        alerts: Alert.open_alerts.limit(20),
        gaps: ResourceGap.order(created_at: :desc).limit(20),
        cases: ShowcaseCase.published.limit(10),
        filter: {
          stage: params[:stage],
          tag_id: params[:tag_id],
          enrollment_status: params[:enrollment_status]
        }
      )
    end

    private

    def district_summary
      scope = current_admin.scoped_students
      {
        total_students: scope.count,
        by_stage: scope.group(:tips_stage).count,
        by_industry: scope.group(:primary_industry).count,
        enrollments: current_admin.scoped_enrollments.group(:status).count
      }
    end

    def filter_students(scope)
      scope = scope.where(tips_stage: params[:stage]) if params[:stage].present?
      if params[:tag_id].present?
        scope = scope.joins(:student_tags).where(student_tags: { tag_id: params[:tag_id] })
      end
      if params[:enrollment_status].present?
        scope = scope.joins(:enrollments).where(enrollments: { status: params[:enrollment_status] })
      end
      scope.distinct
    end
  end
end
