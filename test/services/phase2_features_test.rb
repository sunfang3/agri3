# frozen_string_literal: true

require "test_helper"

class Phase2FeaturesTest < ActiveSupport::TestCase
  setup do
    @district = District.create!(name: "P2区", code: "p2-#{SecureRandom.hex(3)}")
    @student = Student.create!(phone: "134#{rand(10_000_000..99_999_999)}", name: "P2", district: @district, scale: 120, annual_income: 300_000)
    @course = Course.create!(title: "P2课", published: true, latitude: 36.68, longitude: 117.06, place: "校区")
    Enrollment.create!(student: @student, course: @course, status: "enrolled")
  end

  test "pdf parse and human approve path" do
    policy = Policy.create!(title: "待解析", published: true)
    parser = Policies::PdfParser.new
    parser.parse(policy)
    assert_equal "pending_review", policy.parse_status
    assert policy.pdf_text.present?
    parser.approve!(policy, overrides: { title: "校对后标题" })
    assert_equal "approved", policy.reload.parse_status
    assert_equal "校对后标题", policy.title
  end

  test "voice note ASR+LLM pipeline" do
    note = VoiceNote.create!(student: @student, course: @course, status: "pending")
    VoiceNotes::Pipeline.new.process!(note)
    assert_equal "structured", note.reload.status
    assert note.transcript.present?
    assert note.structured["topics"].is_a?(Array)
  end

  test "tips stage evaluator uses rules" do
    TipsStageRule.create!(name: "rule-p", stage: "P", conditions: { "min_scale" => 100 }, priority: 5, enabled: true)
    stage = Tips::StageEvaluator.new.apply!(@student)
    assert_equal "P", stage
    assert_equal "P", @student.reload.tips_stage
  end

  test "multi channel push adapters" do
    push = Push::MultiChannel.new
    %w[sms webpush wechat_mp].each do |ch|
      d = push.deliver!(student: @student, channel: ch, title: "t", body: "b", template_key: "tpl")
      assert_equal "sent", d.status
      assert_equal ch, d.channel
    end
  end

  test "qr check-in with gps validation" do
    svc = CheckIns::QrService.new
    token = svc.generate_token(@course)
    check_in = svc.check_in!(student: @student, course: @course, token: token, latitude: 36.6801, longitude: 117.0601)
    assert check_in.gps_valid
    assert check_in.distance_meters < 500
  end

  test "photo watermark includes time and coords" do
    photo = TrainingPhoto.create!(course: @course, student: @student, latitude: 36.68, longitude: 117.06)
    Photos::WatermarkService.new.attach!(photo, taken_at: Time.zone.parse("2026-07-01 10:00"), place: "校区")
    assert_includes photo.watermark_text, "2026-07-01"
    assert_includes photo.watermark_text, "36.68000"
    assert_includes photo.watermark_text, "校区"
  end

  test "feedback reweighter updates match weights" do
    policy = Policy.create!(title: "反馈政策", published: true)
    FeedbackSignal.create!(student: @student, matchable: policy, signal_type: "useful", weight: 1)
    Matching::FeedbackReweighter.new.reweight!
    assert MatchWeight.exists?
  end

  test "city cockpit summary keys" do
    summary = Dashboard::CityCockpit.new.summary
    assert summary.key?(:students_total)
    assert summary.key?(:enrollments_by_status)
  end

  test "survey response recorder is exercisable for three survey types" do
    %w[pre_training daily post_exam].each do |stype|
      survey = Survey.create!(
        title: "P2-#{stype}",
        survey_type: stype,
        course: @course,
        active: true,
        questions: [ { "id" => "q1", "text" => "题", "correct" => "yes" } ]
      )
      response = Surveys::ResponseRecorder.new(survey, @student).record!({ "q1" => "yes" })
      assert_equal survey.id, response.survey_id
      assert_equal "yes", response.answers["q1"]
      assert_equal 100, response.score if stype == "post_exam"
    end
  end
end
