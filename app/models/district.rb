# frozen_string_literal: true

class District < ApplicationRecord
  attribute :active, :boolean
  has_many :students, dependent: :restrict_with_exception
  has_many :admins, dependent: :nullify
  has_many :courses, dependent: :nullify
  has_many :policies, dependent: :nullify
  has_many :mentors, dependent: :nullify

  validates :name, :code, presence: true
  validates :code, uniqueness: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:id) }

  # 济南市县级行政区划（国务院正式区划：10 个市辖区 + 2 个县）
  # 不含高新区/起步区/南部山区等功能区——功能区不在本清单。
  # 顺序：先市辖区（由内向外），后县。
  JINAN_DISTRICTS = [
    # —— 市辖区 ——
    { name: "历下区", code: "lixia",     kind: "district", sort: 1 },
    { name: "市中区", code: "shizhong",  kind: "district", sort: 2 },
    { name: "槐荫区", code: "huaiyin",   kind: "district", sort: 3 },
    { name: "天桥区", code: "tianqiao",  kind: "district", sort: 4 },
    { name: "历城区", code: "licheng",   kind: "district", sort: 5 },
    { name: "长清区", code: "changqing", kind: "district", sort: 6 },
    { name: "章丘区", code: "zhangqiu",  kind: "district", sort: 7 },
    { name: "济阳区", code: "jiyang",    kind: "district", sort: 8 },
    { name: "莱芜区", code: "laiwu",     kind: "district", sort: 9 },
    { name: "钢城区", code: "gangcheng", kind: "district", sort: 10 },
    # —— 县 ——
    { name: "平阴县", code: "pingyin",   kind: "county",   sort: 11 },
    { name: "商河县", code: "shanghe",   kind: "county",   sort: 12 }
  ].freeze

  JINAN_CODES = JINAN_DISTRICTS.map { |d| d[:code] }.freeze

  def self.seed_jinan!
    JINAN_DISTRICTS.each do |attrs|
      record = find_or_initialize_by(code: attrs[:code])
      record.name = attrs[:name]
      record.active = true
      record.save!
    end

    # 停用非正式区划遗留数据（如历史 seed 中的功能区）
    where.not(code: JINAN_CODES).find_each do |d|
      d.update!(active: false) if d.active?
    end

    where(code: JINAN_CODES).count
  end

  def self.jinan_active
    where(code: JINAN_CODES, active: true)
  end

  def self.meta_for(code)
    JINAN_DISTRICTS.find { |d| d[:code] == code.to_s }
  end

  def kind
    self.class.meta_for(code)&.dig(:kind) || "unknown"
  end

  def district?
    kind == "district"
  end

  def county?
    kind == "county"
  end
end
