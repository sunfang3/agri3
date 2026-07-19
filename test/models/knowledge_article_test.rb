# frozen_string_literal: true

require "test_helper"

class KnowledgeArticleTest < ActiveSupport::TestCase
  test "full_text_search finds Chinese content created via ActiveRecord" do
    KnowledgeArticle.create!(title: "小麦节水灌溉要点", body: "滴灌与测墒提高水分利用效率", published: true)
    KnowledgeArticle.create!(title: "无关文章", body: "其他内容", published: true)

    hits = KnowledgeArticle.full_text_search("节水")
    assert hits.any? { |a| a.title.include?("小麦") }, "expected AR-created article for 节水"
    assert hits.none? { |a| a.title.include?("无关") }
  end

  test "full_text_search finds rows present before FTS rebuild (seed path)" do
    # Insert without going through normal Litesearch after_commit hooks by
    # using the connection, then rebuild — mirrors seed/db:schema:load + data.
    now = Time.current.utc.strftime("%Y-%m-%d %H:%M:%S.%6N")
    KnowledgeArticle.connection.insert(<<~SQL.squish)
      INSERT INTO knowledge_articles (title, body, category, published, created_at, updated_at)
      VALUES (
        '小麦节水灌溉要点-种子',
        '采用滴灌与测墒灌溉，降低亩均用水量',
        '种植',
        1,
        '#{now}',
        '#{now}'
      )
    SQL
    KnowledgeArticle.connection.insert(<<~SQL.squish)
      INSERT INTO knowledge_articles (title, body, category, published, created_at, updated_at)
      VALUES (
        '无关种子文',
        '其他内容占位',
        '其他',
        1,
        '#{now}',
        '#{now}'
      )
    SQL

    # Empty FTS for these rowids until rebuild; full_text_search must still hit.
    hits_节水 = KnowledgeArticle.full_text_search("节水").pluck(:title)
    hits_小麦 = KnowledgeArticle.full_text_search("小麦").pluck(:title)
    hits_滴灌 = KnowledgeArticle.full_text_search("滴灌").pluck(:title)

    assert_includes hits_节水, "小麦节水灌溉要点-种子"
    assert_includes hits_小麦, "小麦节水灌溉要点-种子"
    assert_includes hits_滴灌, "小麦节水灌溉要点-种子"
    assert_not_includes hits_节水, "无关种子文"
  end

  test "blank query returns none" do
    assert_empty KnowledgeArticle.full_text_search("")
    assert_empty KnowledgeArticle.full_text_search(nil)
  end
end
