# frozen_string_literal: true

class Views::StudentApp::Profiles::Show < Views::Base
  def initialize(student:, tags: [], notice: nil)
    @student = student
    @tags = tags
    @notice = notice
  end

  def view_template
    div(class: "mx-auto max-w-lg min-h-dvh bg-base-100 flex flex-col pb-20") do
      header(class: "navbar bg-primary text-primary-content px-4") do
        div(class: "flex-1 font-semibold") { "我的 · 经营画像" }
      end

      section(class: "p-4 space-y-4 flex-1") do
        render Components::Ui::FlashBanner.new(notice: @notice)

        div(class: "stats shadow w-full") do
          div(class: "stat") do
            div(class: "stat-title") { "成长阶段" }
            div(class: "stat-value text-2xl", data: { testid: "tips-stage" }) { @student.tips_stage_label }
            div(class: "stat-desc text-xs leading-snug", data: { testid: "tips-stage-hint" }) { @student.tips_stage_hint }
          end
          div(class: "stat") do
            div(class: "stat-title") { "所在区县" }
            div(class: "stat-value text-lg") { @student.district.name }
          end
        end

        render StudentProfileForm.new(
          model: @student,
          url: student_me_path,
          method: :patch,
          tags: @tags
        )

        div(class: "divider") { "导师语音答疑" }
        Form(url: student_mentor_answers_path, method: :post, scope: false, class: "flex flex-col gap-2") do |f|
          # bare fields — not model-bound
          label(class: "form-control") do
            span(class: "label-text") { "提问" }
            textarea(name: "question", class: "textarea textarea-bordered", required: true, placeholder: "提问")
          end
          label(class: "form-control") do
            span(class: "label-text") { "语音 key（可选）" }
            input(type: "text", name: "audio_key", class: "input input-bordered", placeholder: "触发 ASR")
          end
          f.submit(:outline) { "提交答疑" }
        end

        div(class: "divider") { "学情调查" }
        a(href: student_surveys_path, class: "btn btn-ghost btn-sm") { "训前/训中/训后问卷" }

        div(class: "divider") { "农技知识库" }
        a(href: student_knowledge_index_path, class: "btn btn-ghost btn-sm") { "全文检索知识库" }
      end

      render Components::Student::BottomNav.new(active: :me)
    end
  end
end
