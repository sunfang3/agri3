# frozen_string_literal: true

class Avo::Resources::Course < Avo::BaseResource
  self.title = :title

  def fields
    field :id, as: :id
    field :title, as: :text
    field :description, as: :textarea
    field :mentor_name, as: :text
    field :mentor, as: :belongs_to
    field :starts_at, as: :date_time
    field :ends_at, as: :date_time
    field :place, as: :text
    field :latitude, as: :number
    field :longitude, as: :number
    field :district, as: :belongs_to
    field :published, as: :boolean
    field :tags, as: :has_many
    field :enrollments, as: :has_many
  end
end
