# frozen_string_literal: true

module StudentApp
  class HomeController < ApplicationController
    include StudentAuthenticatable
    before_action :require_student!

    def show
      track_page!("student/home")
      render Views::StudentApp::Workspace.new(student: current_student, page: :home, filter: params.permit(:q, :tier).to_h)
    end
  end
end
