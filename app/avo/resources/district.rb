# frozen_string_literal: true

class Avo::Resources::District < Avo::BaseResource
  self.title = :name

  def fields
    field :id, as: :id
    field :name, as: :text
    field :code, as: :text
    field :active, as: :boolean
  end
end
