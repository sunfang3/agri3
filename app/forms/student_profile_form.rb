# frozen_string_literal: true

class StudentProfileForm < ApplicationForm
  form_options :spaced, method: :patch

  def initialize(tags: [], **options)
    @tags = tags
    super(**options)
  end

  def fields
    field :name, :text, label: "姓名"
    field :primary_industry, :text, label: "主业"
    field :scale, :number, label: "规模", step: :any
    field :annual_income, :number, label: "年收入", step: :any
    field :honors, as: :textarea, label: "荣誉"

    # tag_ids is a virtual multi-select via has_many :tags
    field :tag_ids, as: :checkbox_group,
      collection: @tags,
      value: :id,
      item_label: ->(t) { "#{t.category}:#{t.name}" },
      legend: "标签（可修正）"

    submit(:primary) { "保存画像" }
  end
end
