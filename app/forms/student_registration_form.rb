# frozen_string_literal: true

class StudentRegistrationForm < ApplicationForm
  form_options :spaced, url: "/student/register", method: :post

  def fields
    field :phone, label: "手机号", required: true
    field :name, label: "姓名", required: true
    field :district_id, label: "区县", as: :select,
      choices: District.jinan_active.order(:name).map { |d| [ d.name, d.id ] },
      include_blank: "选择区县",
      required: true
    field :primary_industry, label: "主业"
    field :scale, :number, label: "规模（亩）", step: :any
    field :annual_income, :number, label: "年收入", step: :any
    field :honors, as: :textarea, label: "已获荣誉"
    field :password, label: "密码"
    submit(:primary) { "注册" }
  end
end
