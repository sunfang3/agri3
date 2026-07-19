# frozen_string_literal: true

module AdminApp
  class SurveysController < AdminApp::BaseController
    def index
      render Views::AdminApp::Surveys::Index.new(surveys: Survey.order(created_at: :desc).includes(:course))
    end

    def new
      render Views::AdminApp::Surveys::New.new(
        survey: Survey.new(survey_type: "pre_training", active: true),
        courses: Course.order(:title)
      )
    end

    def create
      survey = Survey.new(survey_params)
      survey.questions = parse_questions(params[:questions_json])
      if survey.save
        track_admin_action!("survey_create", { id: survey.id, survey_type: survey.survey_type })
        redirect_to admin_surveys_path, notice: "学情调查已创建"
      else
        render Views::AdminApp::Surveys::New.new(
          survey:,
          courses: Course.order(:title),
          questions_json: params[:questions_json].to_s
        ), status: :unprocessable_entity
      end
    end

    private

    def survey_params
      params.require(:survey).permit(:title, :survey_type, :course_id, :active)
    end

    def parse_questions(raw)
      return [] if raw.blank?

      JSON.parse(raw)
    rescue JSON::ParserError
      []
    end
  end
end
