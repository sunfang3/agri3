# frozen_string_literal: true

class Views::StudentApp::Surveys::Show < Views::Base
  def initialize(survey:, response: nil, notice: nil, alert: nil)
    @survey = survey
    @response = response
    @notice = notice
    @alert = alert
  end

  def view_template
    div(class: "mx-auto max-w-lg p-4 space-y-4") do
      h1(class: "text-xl font-bold") { @survey.title }
      p(class: "text-sm opacity-70") { "类型：#{@survey.survey_type}" }
      render Components::Ui::FlashBanner.new(notice: @notice, alert: @alert)

      if @response
        div(class: "alert alert-info text-sm") do
          plain "已提交"
          plain " · 得分 #{@response.score}" if @response.score.present?
        end
        pre(class: "text-xs bg-base-200 p-3 rounded overflow-auto") { JSON.pretty_generate(@response.answers) }
      else
        Form(url: respond_student_survey_path(@survey), method: :post, scope: false, class: "flex flex-col gap-3") do |f|
          questions = Array(@survey.questions)
          if questions.empty?
            label(class: "form-control") do
              span(class: "label-text") { "反馈 / 需求" }
              textarea(name: "answers[feedback]", class: "textarea textarea-bordered", required: true)
            end
          else
            questions.each_with_index do |q, i|
              key = q["id"].presence || i.to_s
              label(class: "form-control") do
                span(class: "label-text") { q["text"] || key }
                input(type: "text", name: "answers[#{key}]", class: "input input-bordered", required: true)
              end
            end
          end
          f.submit(:primary) { "提交答卷" }
        end
      end

      a(href: student_surveys_path, class: "btn btn-ghost") { "返回列表" }
    end
  end
end
