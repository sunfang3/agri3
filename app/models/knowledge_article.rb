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

  def self.full_text_search(query)
    return none if query.blank?

    term = query.to_s.strip
    return none if term.blank?

    begin
      ensure_search_index!
      ids = search(term).pluck(:id)
      return none if ids.empty?

      published.where(id: ids)
    rescue StandardError
      q = "%#{sanitize_sql_like(term)}%"
      published.where("lower(title) LIKE lower(?) OR lower(body) LIKE lower(?)", q, q)
    end
  end

  def self.ensure_search_index!
    # Touch the index definition so Litesearch creates FTS tables if missing.
    connection.search_index(index_name) if connection.respond_to?(:search_index)
  rescue StandardError
    # index creation may fail mid-schema load; LIKE fallback still works
    nil
  end
  private_class_method :ensure_search_index!
end
