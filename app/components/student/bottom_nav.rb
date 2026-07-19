# frozen_string_literal: true

class Components::Student::BottomNav < Components::Base
  def initialize(active: :home)
    @active = active.to_sym
  end

  def view_template
    nav(class: "btm-nav btm-nav-sm bg-base-100 border-t fixed bottom-0 left-0 right-0 max-w-lg mx-auto") do
      a(href: student_home_path, class: tab_class(:home)) { span(class: "btm-nav-label") { "首页" } }
      a(href: student_me_path, class: tab_class(:me)) { span(class: "btm-nav-label") { "我的" } }
    end
  end

  private

  def tab_class(key)
    key == @active ? "active text-primary" : nil
  end
end
