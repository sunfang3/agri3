# frozen_string_literal: true

class AdminLogin
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email, :string
  attribute :password, :string

  validates :email, :password, presence: true
end
