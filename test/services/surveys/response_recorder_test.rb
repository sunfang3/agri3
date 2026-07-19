# frozen_string_literal: true

require "test_helper"

class Surveys::ResponseRecorderTest < ActiveSupport::TestCase
  setup do
    @district = District.create!(name: "问卷区", code: "sv-#{SecureRandom.hex(3)}")
    @student = Student.create!(
      phone: "130#{rand(10_000_000..99_999_999)}",
      name: "答卷人",
      district: @district,
      password: "secret"
    )
    @course = Course.create!(title: "问卷课", published: true)
  end

  test "records pre_training answers without score" do
    survey = Survey.create!(
      title: "训前需求",
      survey_type: "pre_training",
      course: @course,
      active: true,
      questions: [ { "id" => "need", "text" => "最需要什么" } ]
    )
    response = Surveys::ResponseRecorder.new(survey, @student).record!({ "need" => "贷款政策" })
    assert_equal "贷款政策", response.answers["need"]
    assert_nil response.score
  end

  test "post_exam computes score from correct answers" do
    survey = Survey.create!(
      title: "训后考试",
      survey_type: "post_exam",
      course: @course,
      active: true,
      questions: [
        { "id" => "q1", "text" => "题1", "correct" => "a" },
        { "id" => "q2", "text" => "题2", "correct" => "b" }
      ]
    )
    response = Surveys::ResponseRecorder.new(survey, @student).record!({ "q1" => "a", "q2" => "x" })
    assert_equal 50, response.score
  end

  test "inactive survey raises" do
    survey = Survey.create!(title: "停用", survey_type: "daily", active: false)
    assert_raises(ArgumentError) do
      Surveys::ResponseRecorder.new(survey, @student).record!({ "x" => "y" })
    end
  end
end
