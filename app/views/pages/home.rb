# frozen_string_literal: true

class Views::Pages::Home < Views::Base
  include Phlex::Rails::Helpers::TurboStreamFrom

  def view_template
    turbo_stream_from Components::Broadcasting::STREAM

    div(class: "mx-auto flex min-h-screen max-w-3xl flex-col justify-center gap-8 px-6 py-16") do
      div(class: "space-y-3") do
        div(class: "badge badge-primary badge-outline") { "Plexy template" }
        h1(class: "text-5xl font-black tracking-tight") { "Phlex, Litestack, reactive UI, and forms" }
        p(class: "text-lg text-base-content/70") do
          plain "Use Components::Base for reusable UI, Views::Base for pages, "
          code(class: "kbd kbd-sm") { "ApplicationForm" }
          plain " for phlex-forms classes, and Litestack for SQLite DB, cache, jobs, and cable."
        end
      end

      div(class: "card bg-base-100 shadow-xl") do
        div(class: "card-body") do
          h2(class: "card-title") { "Reactive counter" }
          render Components::Counter.new
        end
      end
    end
  end
end
