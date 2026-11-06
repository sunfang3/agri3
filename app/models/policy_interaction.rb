class PolicyInteraction < ApplicationRecord
  belongs_to :student
  belongs_to :policy
  attribute :saved, :boolean
  attribute :viewed_at, :datetime
  validates :student_id, uniqueness: { scope: :policy_id }
  validates :application_status, inclusion: { in: %w[none applied approved rejected] }
  def status_label = { "none" => "未申报", "applied" => "已申报", "approved" => "已获批", "rejected" => "未获批" }.fetch(application_status)
end
