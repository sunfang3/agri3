# frozen_string_literal: true

class PagesController < ApplicationController
  def home
    render Views::Pages::Home.new(
      districts_count: District.jinan_active.count,
      students_count: Student.count,
      policies_count: Policy.published.count,
      courses_count: Course.published.count
    )
  end
end
