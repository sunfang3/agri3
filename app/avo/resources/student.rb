# frozen_string_literal: true

class Avo::Resources::Student < Avo::BaseResource
  self.title = :name
  self.includes = [ :district, :tags ]
  def fields
    field :id, as: :id
    field :phone, as: :text
    field :name, as: :text
    field :district, as: :belongs_to
    field :primary_industry, as: :text
    field :scale, as: :number
    field :annual_income, as: :number
    field :honors, as: :textarea
    field :tips_stage, as: :select, options: Student::TIPS_STAGE_LABELS.invert,
      help: "起步期/成长期/壮大期/示范期（库内仍存 T/I/P/S）"
    field :tags, as: :has_many
    field :enrollments, as: :has_many
  end
end
