# frozen_string_literal: true

class Avo::Resources::Tag < Avo::BaseResource
  self.title = :name

  def fields
    field :id, as: :id
    field :name, as: :text
    field :category, as: :select, options: Tag::CATEGORIES.index_by(&:itself)
    field :value, as: :text
  end
end
