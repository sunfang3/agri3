# frozen_string_literal: true

class Views::StudentApp::Knowledge::Index < Views::Base
  def initialize(articles: [], query: nil)
    @articles = articles
    @query = query
  end

  def view_template
    div(class: "mx-auto max-w-lg p-4 space-y-4") do
      h1(class: "text-xl font-bold") { "农技知识库" }

      Form(url: student_knowledge_index_path, method: :get, scope: false, class: "flex gap-2") do |f|
        input(type: "search", name: "q", value: @query.to_s, class: "input input-bordered flex-1", placeholder: "全文检索")
        f.submit(:primary) { "搜索" }
      end

      ul(class: "space-y-2") do
        @articles.each do |a|
          li(class: "card bg-base-200") do
            div(class: "card-body p-3") do
              div(class: "font-medium") { a.title }
              div(class: "text-sm opacity-70 line-clamp-3") { a.body }
            end
          end
        end
      end

      a(href: student_me_path, class: "btn btn-ghost") { "返回" }
    end
  end
end
