# frozen_string_literal: true

require "test_helper"
require "caxlsx"

class Students::ExcelImporterTest < ActiveSupport::TestCase
  setup do
    @district = District.create!(name: "导入区", code: "import-#{SecureRandom.hex(3)}")
    @path = Rails.root.join("tmp", "import-#{SecureRandom.hex(4)}.xlsx")
    package = Axlsx::Package.new
    package.workbook.add_worksheet(name: "students") do |sheet|
      sheet.add_row %w[phone name district_code primary_industry scale annual_income honors]
      sheet.add_row [ "13912345678", "导入学员", @district.code, "粮油", 80, 120000, "无" ]
      sheet.add_row [ "bad", "坏行", @district.code, "菜", 10, 1, "" ]
    end
    package.serialize(@path.to_s)
  end

  teardown do
    File.delete(@path) if File.exist?(@path)
  end

  test "dry_run does not persist students" do
    before = Student.count
    result = Students::ExcelImporter.new(@path.to_s).dry_run
    assert result[:dry_run]
    assert_equal before, Student.count
    assert_equal 2, result[:total]
    assert_equal 1, result[:valid]
    assert_equal 1, result[:invalid]
    assert_equal "would_create", result[:rows].find { |r| r.errors.empty? }.action
  end

  test "commit persists valid rows only" do
    result = Students::ExcelImporter.new(@path.to_s).commit!
    refute result[:dry_run]
    assert_equal 1, result[:created]
    student = Student.find_by(phone: "13912345678")
    assert student
    assert_equal "导入学员", student.name
    assert_equal @district.id, student.district_id
    refute Student.exists?(name: "坏行")
  end

  test "commit sets password_digest so blank-password login is impossible" do
    Students::ExcelImporter.new(@path.to_s).commit!
    student = Student.find_by!(phone: "13912345678")
    assert student.password_digest.present?
    assert student.authenticate("13912345678")
    refute student.authenticate("")
    refute student.authenticate("wrong")
  end

  test "optional course_title enrolls city_direct with district ack pending" do
    city_course = Course.create!(title: "导入市直测试班", published: true, district: nil)
    district_course = Course.create!(title: "导入区办测试班", published: true, district: @district)
    path = Rails.root.join("tmp", "import-course-#{SecureRandom.hex(4)}.xlsx")
    Axlsx::Package.new.tap do |package|
      package.workbook.add_worksheet(name: "students") do |sheet|
        sheet.add_row %w[phone name district_code primary_industry scale annual_income honors course_title]
        sheet.add_row [ "13900001111", "市直导入", @district.code, "粮油", 50, 100_000, "", city_course.title ]
        sheet.add_row [ "13900002222", "区办导入", @district.code, "蔬菜", 60, 110_000, "", district_course.title ]
      end
      package.serialize(path.to_s)
    end

    result = Students::ExcelImporter.new(path.to_s).commit!
    assert_equal 2, result[:created]
    assert result[:enrollments_created] >= 2

    e_city = Enrollment.find_by!(student: Student.find_by!(phone: "13900001111"), course: city_course)
    assert_equal "pending", e_city.status
    assert_equal "pending", e_city.district_ack_status
    assert e_city.course.city_direct?

    e_dist = Enrollment.find_by!(student: Student.find_by!(phone: "13900002222"), course: district_course)
    assert_equal "pending", e_dist.status
    assert_equal "not_required", e_dist.district_ack_status
    refute e_dist.course.city_direct?
  ensure
    File.delete(path) if path && File.exist?(path)
  end

  test "unknown course_title invalidates row" do
    path = Rails.root.join("tmp", "import-bad-course-#{SecureRandom.hex(4)}.xlsx")
    Axlsx::Package.new.tap do |package|
      package.workbook.add_worksheet(name: "students") do |sheet|
        sheet.add_row %w[phone name district_code primary_industry scale annual_income honors course_title]
        sheet.add_row [ "13900003333", "坏课", @district.code, "粮油", 10, 1, "", "不存在的课程标题" ]
      end
      package.serialize(path.to_s)
    end
    result = Students::ExcelImporter.new(path.to_s).dry_run
    assert_equal 1, result[:invalid]
    assert_includes result[:rows].first.errors.join, "course_title"
  ensure
    File.delete(path) if path && File.exist?(path)
  end
end
