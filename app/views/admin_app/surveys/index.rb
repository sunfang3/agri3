# frozen_string_literal: true

class Views::AdminApp::Surveys::Index < Views::Base
  def initialize(surveys: [])
    @surveys = surveys
  end

  def view_template
    div(class: "mx-auto max-w-3xl px-4 py-8 space-y-4") do
      div(class: "flex justify-between items-center") do
        h1(class: "text-xl font-bold") { "学情调查" }
        a(href: new_admin_survey_path, class: "btn btn-primary btn-sm") { "新建调查" }
      end
      ul(class: "space-y-2") do
        @surveys.each do |s|
          li(class: "card bg-base-100 shadow-sm") do
            div(class: "card-body p-4 gap-1") do
              div(class: "font-medium") { s.title }
              div(class: "text-xs opacity-70") do
                "类型=#{s.survey_type} · 课程=#{s.course&.title || "—"} · 题数=#{Array(s.questions).size} · #{s.active? ? "启用" : "停用"}"
              end
            end
          end
        end
      end
      a(href: admin_root_path, class: "btn btn-ghost") { "返回" }
    end
  end
end
