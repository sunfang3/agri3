# frozen_string_literal: true

require "test_helper"

class AnalyticsEventTest < ActiveSupport::TestCase
  test "track login key_action and page_view" do
    district = District.create!(name: "埋点区", code: "an-#{SecureRandom.hex(3)}")
    student = Student.create!(phone: "135#{rand(10_000_000..99_999_999)}", name: "埋点", district: district)

    login = AnalyticsEvent.track!(event_type: "login", actor: student, page: "student/login", district_code: district.code)
    action = AnalyticsEvent.track!(event_type: "key_action", actor: student, action_name: "enroll", payload: { course_id: 1 })
    view = AnalyticsEvent.track!(event_type: "page_view", actor: student, page: "student/home")

    assert_equal "login", login.event_type
    assert_equal "key_action", action.event_type
    assert_equal "page_view", view.event_type
    assert_equal 3, AnalyticsEvent.where(actor: student).count
  end
end
