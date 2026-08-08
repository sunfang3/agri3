# frozen_string_literal: true

module StudentApp
  class HomeController < ApplicationController
    include StudentAuthenticatable
    before_action :require_student!

    def show
      track_page!("student/home")
      matches = current_student.resource_matches.includes(:matchable).ranked
      courses = Course.published.order(starts_at: :asc).limit(20)
      enrollments_by_course = current_student.enrollments.index_by(&:course_id)
      render Views::StudentApp::Home::Show.new(
        tier1: matches.select { |m| m.priority_tier == 1 },
        tier2: matches.select { |m| m.priority_tier == 2 },
        tier3: matches.select { |m| m.priority_tier == 3 },
        courses: courses,
        enrollments_by_course: enrollments_by_course,
        unread_count: current_student.unread_message_count
      )
    end
  end
end
