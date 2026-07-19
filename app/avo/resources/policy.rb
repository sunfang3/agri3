# frozen_string_literal: true

class Avo::Resources::Policy < Avo::BaseResource
  self.title = :title

  def fields
    field :id, as: :id
    field :title, as: :text
    field :content_text, as: :textarea
    field :valid_until, as: :date
    field :pdf_text, as: :textarea
    field :parse_status, as: :select, options: {
      "manual" => "manual",
      "pending_review" => "pending_review",
      "approved" => "approved"
    }
    field :district, as: :belongs_to
    field :published, as: :boolean
    field :tags, as: :has_many
    field :pdf, as: :file
  end
end
