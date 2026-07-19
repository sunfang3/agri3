# frozen_string_literal: true

# Bare login credentials — no AR model; used with Form(scope: false).
class StudentLogin
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :phone, :string
  attribute :password, :string

  validates :phone, presence: true
end
