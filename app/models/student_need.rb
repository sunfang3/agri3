class StudentNeed < ApplicationRecord
  belongs_to :student
  validates :body, presence: true, length: { maximum: 2000 }
  validates :status, inclusion: { in: %w[pending processing responded] }
  validates :response, presence: true, if: -> { status == "responded" }
  def status_label = { "pending" => "待响应", "processing" => "处理中", "responded" => "已响应" }.fetch(status)
end
