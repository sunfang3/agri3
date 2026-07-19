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
end
