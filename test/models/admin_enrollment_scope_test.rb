# frozen_string_literal: true

require "test_helper"

class AdminEnrollmentScopeTest < ActiveSupport::TestCase
  setup do
    @licheng = District.create!(name: "历城测", code: "sc-lc-#{SecureRandom.hex(3)}")
    @shizhong = District.create!(name: "市中测", code: "sc-sz-#{SecureRandom.hex(3)}")
    @district_admin = Admin.create!(
      name: "区管",
      email: "da-#{SecureRandom.hex(3)}@test.local",
      password: "password",
      role: "district",
      district: @licheng
    )
    @city_admin = Admin.create!(
      name: "市管",
      email: "ca-#{SecureRandom.hex(3)}@test.local",
      password: "password",
      role: "city"
    )
    @student_lc = Student.create!(
      phone: "131#{rand(10_000_000..99_999_999)}",
      name: "历城学员",
      district: @licheng,
      password: "secret"
    )
    @student_sz = Student.create!(
      phone: "131#{rand(10_000_000..99_999_999)}",
      name: "市中学员",
      district: @shizhong,
      password: "secret"
    )
    @city_course = Course.create!(title: "市直高产班", published: true, district: nil)
    @licheng_course = Course.create!(title: "历城小麦班", published: true, district: @licheng)
    @shizhong_course = Course.create!(title: "市中农旅班", published: true, district: @shizhong)

    @e_city = Enrollment.create!(student: @student_lc, course: @city_course, status: "pending")
    @e_lc = Enrollment.create!(student: @student_lc, course: @licheng_course, status: "pending")
    @e_cross = Enrollment.create!(student: @student_sz, course: @licheng_course, status: "pending")
    @e_sz = Enrollment.create!(student: @student_sz, course: @shizhong_course, status: "pending")
  end

  test "district admin only reviews courses owned by their district" do
    ids = @district_admin.scoped_enrollments.pluck(:id)
    assert_includes ids, @e_lc.id
    assert_includes ids, @e_cross.id, "外区学员报本区班仍由开班区审核"
    refute_includes ids, @e_city.id, "市直班不进区县待审"
    refute_includes ids, @e_sz.id
  end

  test "city admin only reviews city-direct courses (no course district)" do
    ids = @city_admin.scoped_enrollments.pluck(:id)
    assert_includes ids, @e_city.id
    refute_includes ids, @e_lc.id
    refute_includes ids, @e_sz.id
    refute_includes ids, @e_cross.id
  end

  test "district admin bulk confirm cannot confirm city-direct enrollment" do
    scope = @district_admin.scoped_enrollments.where(id: [ @e_city.id, @e_lc.id ])
    confirmed = Enrollment.bulk_confirm!(scope.pluck(:id))
    assert_equal 1, confirmed.size
    assert_equal "enrolled", @e_lc.reload.status
    assert_equal "pending", @e_city.reload.status
  end

  test "city admin bulk confirm only city-direct" do
    scope = @city_admin.scoped_enrollments.where(id: [ @e_city.id, @e_lc.id ])
    confirmed = Enrollment.bulk_confirm!(scope.pluck(:id))
    assert_equal 1, confirmed.size
    assert_equal "enrolled", @e_city.reload.status
    assert_equal "pending", @e_lc.reload.status
  end
end
