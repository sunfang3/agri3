# frozen_string_literal: true

module StudentApp
  class MentorAnswersController < ApplicationController
    include StudentAuthenticatable
    before_action :require_student!

    def create
      answer = current_student.mentor_answers.create!(
        question: params[:question],
        mentor_id: params[:mentor_id],
        status: "open"
      )
      # Voice answer path: if audio_key provided, mark as answered with stub transcript
      if params[:audio_key].present?
        answer.update!(
          audio_key: params[:audio_key],
          answer_text: Adapters::FakeAsr.new.transcribe(params[:audio_key]),
          status: "answered",
          mentor_id: params[:mentor_id].presence || Mentor.first&.id
        )
      end
      track_action!("mentor_qa", { mentor_answer_id: answer.id })
      redirect_to student_me_path, notice: "已提交导师答疑"
    end
  end
end
