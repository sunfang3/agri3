# frozen_string_literal: true

class KnowledgeArticle < ApplicationRecord
  validates :title, :body, presence: true

  scope :published, -> { where(published: true) }

  # Litesearch is wired in Unit 6; SQLite-safe fallback uses LIKE (case-insensitive via lower()).
  def self.full_text_search(query)
    return none if query.blank?

    q = "%#{sanitize_sql_like(query.to_s.strip)}%"
    published.where("lower(title) LIKE lower(?) OR lower(body) LIKE lower(?)", q, q)
  end
end
