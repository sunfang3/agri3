# frozen_string_literal: true

require "test_helper"

class Dashboard::CityCockpitTest < ActiveSupport::TestCase
  test "materialize writes snapshot rows without Postgres matview" do
    d = District.create!(name: "驾驶舱区", code: "cp-#{SecureRandom.hex(3)}")
    Student.create!(phone: "135#{rand(10_000_000..99_999_999)}", name: "A", district: d, password: "x")
    cockpit = Dashboard::CityCockpit.new
    assert cockpit.materialize!
    rows = cockpit.district_stats_from_mv
    assert rows.any? { |r| r["district_name"] == d.name || r["district_name"] == d.name }
    summary = cockpit.summary
    assert summary[:students_total] >= 1
  end
end
