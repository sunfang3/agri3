# frozen_string_literal: true

class Views::AdminApp::Surveys::New < Views::Base
  def initialize(survey:, courses: [], questions_json: "")
    @survey = survey
    @courses = courses
    @questions_json = questions_json
  end

  def view_template
    div(class: "mx-auto max-w-lg px-4 py-8") do
      h1(class: "text-xl font-bold mb-4") { "新建学情调查" }
      if @survey.errors.any?
        div(class: "alert alert-error text-sm mb-3") { @survey.errors.full_messages.join(", ") }
      end

      Form(model: @survey, url: admin_surveys_path, method: :post, class: "flex flex-col gap-3") do |f|
        f.field :title, label: "标题", required: true
        f.field :survey_type, label: "类型", as: :select, choices: Survey::TYPES.map { |t| [ t, t ] }
        f.field :course_id, label: "课程", as: :select,
          choices: @courses.map { |c| [ c.title, c.id ] },
          include_blank: "不绑定课程"
        f.field :active, as: :toggle, label: "启用"
        label(class: "form-control") do
          span(class: "label-text text-sm") { "题目 JSON（可选）" }
          textarea(
            name: "questions_json",
            class: "textarea textarea-bordered font-mono text-xs",
            rows: 6,
            placeholder: '[{"id":"q1","text":"需求？","correct":"a"}]'
          ) { @questions_json }
        end
        f.submit(:primary) { "创建" }
      end

      a(href: admin_surveys_path, class: "btn btn-ghost mt-2") { "返回" }
    end
  end
end
