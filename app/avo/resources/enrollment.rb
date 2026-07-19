# frozen_string_literal: true

class Avo::Resources::Enrollment < Avo::BaseResource
  self.title = :id
  self.includes = [ :student, :course ]

  def fields
    field :id, as: :id
    field :student, as: :belongs_to
    field :course, as: :belongs_to
    field :status, as: :select, options: {
      "pending" => "pending",
      "enrolled" => "enrolled",
      "completed" => "completed",
      "dropped" => "dropped"
    }
    field :confirmed_at, as: :date_time
  end
end
