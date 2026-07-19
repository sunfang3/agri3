# frozen_string_literal: true

class Views::StudentApp::Messages::Index < Views::Base
  def initialize(messages: [])
    @messages = messages
  end

  def view_template
    div(class: "mx-auto max-w-lg p-4") do
      h1(class: "text-xl font-bold mb-4") { "消息" }
      ul(class: "space-y-2") do
        @messages.each do |msg|
          li(class: "card bg-base-200") do
            div(class: "card-body p-3") do
              div(class: "font-medium") { msg.title }
              div(class: "text-sm opacity-70") { msg.body.to_s }
            end
          end
        end
      end
      a(href: student_home_path, class: "btn btn-ghost mt-4") { "返回首页" }
    end
  end
end
