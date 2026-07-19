# frozen_string_literal: true

class ChatIdentity
  include ActiveModel::Model

  attr_reader :nickname

  validates :nickname, length: { in: 2..20 }

  def nickname=(value)
    @nickname = value.to_s.strip
  end
end
