# frozen_string_literal: true

module StudentApp
  class MessagesController < ApplicationController
    include StudentAuthenticatable
    before_action :require_student!

    def index
      track_page!("student/messages")
      messages = current_student.app_messages.order(created_at: :desc)
      current_student.app_messages.unread.find_each(&:mark_read!)
      render Views::StudentApp::Messages::Index.new(messages:)
    end
  end
end
