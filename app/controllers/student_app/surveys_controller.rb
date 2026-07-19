# frozen_string_literal: true

module StudentApp
  class SurveysController < ApplicationController
    include StudentAuthenticatable
    before_action :require_student!

    def index
      track_page!("student/surveys")
      surveys = Survey.active.order(created_at: :desc)
      responses = current_student.survey_responses.index_by(&:survey_id)
      render Views::StudentApp::Surveys::Index.new(surveys:, responses:)
    end

    def show
      survey = Survey.active.find(params[:id])
      response = current_student.survey_responses.find_by(survey:)
      track_page!("student/surveys/#{survey.id}")
      render Views::StudentApp::Surveys::Show.new(
        survey:,
        response:,
        notice: flash[:notice],
        alert: flash[:alert]
      )
    end

    def respond
      survey = Survey.active.find(params[:id])
      answers = params[:answers] || {}
      response = Surveys::ResponseRecorder.new(survey, current_student).record!(answers)
      track_action!("survey_respond", { survey_id: survey.id, survey_type: survey.survey_type, score: response.score })
      redirect_to student_survey_path(survey), notice: "答卷已提交"
    rescue ArgumentError => e
      redirect_to student_survey_path(survey), alert: e.message
    end
  end
end
