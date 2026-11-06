# frozen_string_literal: true

class PolicyForm < ApplicationForm
  form_options :spaced, method: :post

  def initialize(tags: [], **options)
    @tags = tags
    super(**options)
  end

  def fields
    field :title, :text, label: "标题", required: true
    field :document_number, :text, label: "政策文号"
    field :issuing_authority, :text, label: "发布单位"
    field :content_text, as: :textarea, label: "正文"
    field :pdf_text, as: :textarea, label: "政策原文（用于提取与校对）"
    field :published, as: :boolean, label: "发布给学员"
    field :valid_until, :date, label: "有效期至"
    field :district_id, label: "区县", as: :select,
      choices: District.jinan_active.order(:name).map { |d| [ d.name, d.id ] },
      include_blank: "全市"
    field :tag_ids, as: :checkbox_group,
      collection: @tags,
      value: :id,
      item_label: ->(t) { "#{t.category}:#{t.name}" },
      legend: "标签"
    submit(:primary) { "保存" }
  end
end
