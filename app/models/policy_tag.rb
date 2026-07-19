# frozen_string_literal: true

class PolicyTag < ApplicationRecord
  belongs_to :policy
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :policy_id }
end
