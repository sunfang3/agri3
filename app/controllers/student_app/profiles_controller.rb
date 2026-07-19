# frozen_string_literal: true

module StudentApp
  class ProfilesController < ApplicationController
    include StudentAuthenticatable
    before_action :require_student!

    def show
      track_page!("student/me")
      render_profile(notice: flash[:notice])
    end

    def update
      student = current_student
      tag_ids = Array(params.dig(:student, :tag_ids) || params[:tag_ids]).map(&:to_i).reject(&:zero?)
      student.correct_tags!(tag_ids) if tag_ids.any? || params.dig(:student, :tag_ids)
      track_action!("correct_tags", { tag_ids: tag_ids }) if tag_ids.any?

      if student.update(profile_params)
        Tips::StageEvaluator.new.apply!(student)
        redirect_to student_me_path, notice: "画像已更新"
      else
        render_profile(student:, status: :unprocessable_entity)
      end
    end

    private

    def render_profile(student: current_student, notice: nil, status: :ok)
      render Views::StudentApp::Profiles::Show.new(
        student:,
        tags: Tag.order(:category, :name),
        notice:
      ), status:
    end

    def profile_params
      params.fetch(:student, {}).permit(:name, :primary_industry, :scale, :annual_income, :honors, tag_ids: [])
    end
  end
end
