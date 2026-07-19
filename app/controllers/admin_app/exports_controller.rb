# frozen_string_literal: true

require "csv"

module AdminApp
  class ExportsController < AdminApp::BaseController
    def students
      students = current_admin.scoped_students.includes(:district)
      csv = CSV.generate(headers: true) do |out|
        out << %w[id phone name district primary_industry scale annual_income tips_stage honors]
        students.find_each do |s|
          out << [ s.id, s.phone, s.name, s.district.name, s.primary_industry, s.scale, s.annual_income, s.tips_stage, s.honors ]
        end
      end
      track_admin_action!("csv_export", { resource: "students", count: students.count })
      send_data csv, filename: "students-#{Date.current}.csv", type: "text/csv"
    end
  end
end
