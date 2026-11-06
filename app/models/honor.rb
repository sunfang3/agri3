class Honor < ApplicationRecord
  include ValidatesUpload
  belongs_to :student
  has_one_attached :evidence
  validates_upload :evidence, types: %w[image/jpeg image/png image/webp application/pdf], maximum: 10.megabytes
  attribute :awarded_on, :date
  validates :title, presence: true, length: { maximum: 200 }
  validates :status, inclusion: { in: %w[pending approved rejected] }
  def status_label = { "pending" => "待审核", "approved" => "已通过", "rejected" => "未通过" }.fetch(status)
end
