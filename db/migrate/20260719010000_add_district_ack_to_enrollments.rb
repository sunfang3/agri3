# frozen_string_literal: true

class AddDistrictAckToEnrollments < ActiveRecord::Migration[8.1]
  def change
    add_column :enrollments, :district_ack_status, :string, default: "not_required", null: false
    add_column :enrollments, :district_acked_at, :datetime
    add_column :enrollments, :district_ack_admin_id, :integer
    add_index :enrollments, :district_ack_status
  end
end
