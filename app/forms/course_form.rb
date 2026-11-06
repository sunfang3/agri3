# frozen_string_literal: true

class CourseForm < ApplicationForm
  form_options :spaced, method: :post

  def initialize(tags: [], mentors: [], **options)
    @tags = tags
    @mentors = mentors
    super(**options)
  end

  def fields
    field :title, :text, label: "标题", required: true
    field :description, as: :textarea, label: "简介"
    field :mentor_name, :text, label: "导师姓名"
    field :mentor_id, label: "师资库", as: :select,
      choices: @mentors.map { |m| [ m.name, m.id ] },
      include_blank: "师资库"
    field :starts_at, :datetime_local, label: "开始时间"
    field :ends_at, :datetime_local, label: "结束时间"
    field :capacity, :number, label: "课程容量（留空不限）", min: 1
    field :place, :text, label: "地点"
    field :latitude, :number, label: "纬度", step: :any
    field :longitude, :number, label: "经度", step: :any
    field :district_id, label: "开班归属", as: :select,
      choices: District.jinan_active.order(:name).map { |d| [ d.name, d.id ] },
      include_blank: "市直班（市级审核）"
    field :published, as: :boolean, label: "发布"
    field :tag_ids, as: :checkbox_group,
      collection: @tags,
      value: :id,
      item_label: :name,
      legend: "深度标签"
    submit(:primary) { "保存" }
  end
end
