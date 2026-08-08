# frozen_string_literal: true

require "test_helper"

class CourseDatetimeCastTest < ActiveSupport::TestCase
  test "starts_on_label works when starts_at is a Time" do
    course = Course.create!(
      title: "时间课-#{SecureRandom.hex(2)}",
      published: true,
      starts_at: Time.zone.parse("2026-08-15 09:00:00")
    )
    assert_equal "2026-08-15", course.starts_on_label
    assert_includes course.time_range_label, "2026-08-15"
  end

  test "starts_on_label works when starts_at is a raw string (Litedb production shape)" do
    course = Course.create!(title: "字符串时间课-#{SecureRandom.hex(2)}", published: true)
    # Simulate Litedb returning untyped text for datetime columns
    course.write_attribute(:starts_at, "2026-08-18 09:00:00 UTC")
    course.write_attribute(:ends_at, "2026-08-19 17:00:00 UTC")
    # Bypass attribute cast by stubbing readers if cast already applied
    course.define_singleton_method(:starts_at) { "2026-08-18 09:00:00 UTC" }
    course.define_singleton_method(:ends_at) { "2026-08-19 17:00:00 UTC" }
    assert_equal "2026-08-18", course.starts_on_label
    assert_includes course.time_range_label, "2026-08-18"
    assert_includes course.time_range_label, "2026-08-19"
  end

  test "attribute cast turns string assignment into Time" do
    course = Course.new(title: "cast-#{SecureRandom.hex(2)}", published: true)
    course.starts_at = "2026-09-01 10:30:00"
    assert_kind_of ActiveSupport::TimeWithZone, course.starts_at
    assert_equal 9, course.starts_at.month
  end
end
