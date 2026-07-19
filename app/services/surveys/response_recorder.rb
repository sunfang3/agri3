# frozen_string_literal: true

module Surveys
  # Records student survey answers and optional score for post_exam.
  class ResponseRecorder
    def initialize(survey, student)
      @survey = survey
      @student = student
    end

    def record!(answers)
      raise ArgumentError, "survey inactive" unless @survey.active?

      response = SurveyResponse.find_or_initialize_by(survey: @survey, student: @student)
      response.answers = normalize(answers)
      response.score = compute_score(response.answers) if @survey.survey_type == "post_exam"
      response.save!
      response
    end

    private

    def normalize(answers)
      case answers
      when ActionController::Parameters then answers.to_unsafe_h
      when Hash then answers.stringify_keys
      else {}
      end
    end

    def compute_score(answers)
      questions = Array(@survey.questions)
      return nil if questions.empty?

      correct = 0
      total = 0
      questions.each_with_index do |q, i|
        key = q["id"].presence || i.to_s
        next unless q.key?("correct")

        total += 1
        correct += 1 if answers[key].to_s == q["correct"].to_s
      end
      return 0 if total.zero?

      ((correct.to_f / total) * 100).round
    end
  end
end
