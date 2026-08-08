# frozen_string_literal: true

class ChatIdentity
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :nickname, :string

  validates :nickname, presence: true, length: { in: 2..20 }

  def nickname=(value)
    super(value.to_s.strip)
  end
end
