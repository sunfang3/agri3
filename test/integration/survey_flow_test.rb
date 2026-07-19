# frozen_string_literal: true

require "test_helper"

class SurveyFlowTest < ActionDispatch::IntegrationTest
  setup do
    @district = District.create!(name: "学情区", code: "sf-#{SecureRandom.hex(3)}")
    @admin = Admin.create!(
      name: "管",
      email: "survey-admin-#{SecureRandom.hex(3)}@test.local",
      password: "password",
      role: "district",
      district: @district
    )
    @student = Student.create!(
      phone: "131#{rand(10_000_000..99_999_999)}",
      name: "学情学员",
      district: @district,
      password: "secret"
    )
    @course = Course.create!(title: "学情课", published: true, district: @district)
  end

  test "admin creates survey and student responds" do
    post admin_login_path, params: { email: @admin.email, password: "password" }
    follow_redirect!

    assert_difference -> { Survey.count }, 1 do
      post admin_surveys_path, params: {
        survey: {
          title: "训前需求调研",
          survey_type: "pre_training",
          course_id: @course.id,
          active: true
        },
        questions_json: [ { id: "need", text: "培训需求" } ].to_json
      }
    end
    assert_redirected_to admin_surveys_path
    survey = Survey.order(:id).last
    assert_equal "pre_training", survey.survey_type
    assert survey.active?

    get admin_surveys_path
    assert_response :success
    assert_match(/训前需求调研/, response.body)

    post student_login_path, params: { phone: @student.phone, password: "secret" }
    follow_redirect!

    get student_surveys_path
    assert_response :success
    assert_match(/训前需求调研/, response.body)

    get student_survey_path(survey)
    assert_response :success

    assert_difference -> { SurveyResponse.count }, 1 do
      post respond_student_survey_path(survey), params: { answers: { need: "节水灌溉" } }
    end
    assert_redirected_to student_survey_path(survey)
    follow_redirect!
    assert_match(/已提交|节水灌溉/, response.body)

    response_row = SurveyResponse.find_by!(survey: survey, student: @student)
    assert_equal "节水灌溉", response_row.answers["need"]
    assert AnalyticsEvent.where(event_type: "key_action", action_name: "survey_respond").exists?
  end
end
