# frozen_string_literal: true

class Views::StudentApp::Surveys::Index < Views::Base
  def initialize(surveys: [], responses: {})
    @surveys = surveys
    @responses = responses
  end

  def view_template
    div(class: "mx-auto max-w-lg p-4 space-y-4 pb-20") do
      h1(class: "text-xl font-bold") { "学情调查" }
      ul(class: "space-y-2") do
        @surveys.each do |s|
          answered = @responses[s.id]
          li(class: "card bg-base-200") do
            div(class: "card-body p-3 flex-row items-center justify-between") do
              div do
                div(class: "font-medium") { s.title }
                div(class: "text-xs opacity-70") { "#{s.survey_type}#{answered ? " · 已答" : ""}" }
              end
              a(href: student_survey_path(s), class: "btn btn-sm btn-primary") { answered ? "查看" : "填写" }
            end
          end
        end
      end
      a(href: student_me_path, class: "btn btn-ghost") { "返回我的" }
    end
  end
end
