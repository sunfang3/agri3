# frozen_string_literal: true

class KnowledgeArticle < ApplicationRecord
  attribute :published, :boolean

  include Litesearch::Model

  validates :title, :body, presence: true

  scope :published, -> { where(published: true) }

  litesearch do |schema|
    schema.fields %i[title body]
    path = begin
      Rails.application.config.litestack.try(:simple_extension_path)
    rescue StandardError
      nil
    end
    schema.tokenizer(path.present? && File.exist?(path.to_s) ? :simple : :unicode61)
  end

  # Prefer Litesearch FTS, always union with LIKE so seed/import rows that
  # predate the FTS index (or partial indexes) remain discoverable.
  def self.full_text_search(query)
    return none if query.blank?

    term = query.to_s.strip
    return none if term.blank?

    like_ids = like_scope(term).pluck(:id)
    fts_ids = fts_match_ids(term)

    # Stale FTS: content matches LIKE but not FTS → rebuild once and retry FTS.
    if like_ids.any? && (fts_ids.empty? || (like_ids - fts_ids).any?)
      rebuild_search_index!
      fts_ids = fts_match_ids(term, rebuild: false)
    end

    ids = (fts_ids | like_ids)
    return none if ids.empty?

    published.where(id: ids)
  end

  def self.rebuild_search_index!
    ensure_search_index!
    rebuild_index! if respond_to?(:rebuild_index!)
  rescue StandardError
    nil
  end

  def self.fts_match_ids(term, rebuild: true)
    ensure_search_index!
    ids = search(term).pluck(:id)
    return ids if ids.any? || !rebuild

    rebuild_search_index!
    search(term).pluck(:id)
  rescue StandardError
    []
  end
  private_class_method :fts_match_ids

  def self.like_scope(term)
    q = "%#{sanitize_sql_like(term)}%"
    published.where("lower(title) LIKE lower(?) OR lower(body) LIKE lower(?)", q, q)
  end
  private_class_method :like_scope

  def self.ensure_search_index!
    connection.search_index(index_name) if connection.respond_to?(:search_index)
  rescue StandardError
    nil
  end
  private_class_method :ensure_search_index!
end
