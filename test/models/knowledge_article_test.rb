# frozen_string_literal: true

require "test_helper"

class KnowledgeArticleTest < ActiveSupport::TestCase
  test "full_text_search finds Chinese content" do
    KnowledgeArticle.create!(title: "小麦节水灌溉要点", body: "滴灌与测墒提高水分利用效率", published: true)
    KnowledgeArticle.create!(title: "无关文章", body: "其他内容", published: true)

    hits = KnowledgeArticle.full_text_search("节水")
    assert hits.any? { |a| a.title.include?("小麦") }
    assert hits.none? { |a| a.title.include?("无关") }
  end

  test "blank query returns none" do
    assert_empty KnowledgeArticle.full_text_search("")
    assert_empty KnowledgeArticle.full_text_search(nil)
  end
end
