# frozen_string_literal: true

module StudentApp
  class KnowledgeController < ApplicationController
    include StudentAuthenticatable
    before_action :require_student!

    def index
      track_page!("student/knowledge")
      query = params[:q]
      articles = if query.present?
        KnowledgeArticle.full_text_search(query).limit(50)
      else
        KnowledgeArticle.published.order(created_at: :desc).limit(50)
      end
      render Views::StudentApp::Knowledge::Index.new(articles:, query:)
    end
  end
end
