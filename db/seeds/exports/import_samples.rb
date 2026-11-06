# frozen_string_literal: true

require "caxlsx"
path = Rails.root.join("tmp/seed_sample_student_import.xlsx")
FileUtils.mkdir_p(path.dirname)
Axlsx::Package.new.tap do |package|
  package.workbook.add_worksheet(name: "students") do |sheet|
    sheet.add_row %w[phone name district_code primary_industry scale annual_income honors course_title]
    demo_multiplier.times do |batch|
      sheet.add_row [ format("137%08d", batch * 3 + 1), "导入市直学员#{batch + 1}", "licheng", "粮油", 90, 200_000, "", demo_course(batch, 0).title ]
      sheet.add_row [ format("137%08d", batch * 3 + 2), "导入区办学员#{batch + 1}", "zhangqiu", "蔬菜", 120, 300_000, "大葱示范", demo_course(batch, 4).title ]
      sheet.add_row [ format("137%08d", batch * 3 + 3), "导入仅建档#{batch + 1}", "pingyin", "花卉", 40, 150_000, "", "" ]
    end
  end
  package.serialize(path.to_s)
end
