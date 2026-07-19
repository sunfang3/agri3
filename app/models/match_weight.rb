# frozen_string_literal: true

class MatchWeight < ApplicationRecord
  attribute :weight, :float
  validates :tag_category, presence: true, uniqueness: true
  validates :weight, numericality: { greater_than: 0 }

  def self.weight_for(category)
    find_by(tag_category: category)&.weight&.to_f || 1.0
  end
end
