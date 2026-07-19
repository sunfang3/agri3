# frozen_string_literal: true

class Student < ApplicationRecord
  attribute :profile, :json
  has_secure_password validations: false

  belongs_to :district
  has_many :student_tags, dependent: :destroy
  has_many :tags, through: :student_tags
  has_many :enrollments, dependent: :destroy
  has_many :courses, through: :enrollments
  has_many :resource_matches, dependent: :destroy
  has_many :app_messages, dependent: :destroy
  has_many :check_ins, dependent: :destroy
  has_many :voice_notes, dependent: :destroy
  has_many :push_deliveries, dependent: :destroy
  has_many :survey_responses, dependent: :destroy
  has_many :feedback_signals, dependent: :destroy
  has_many :attributions, dependent: :destroy
  has_many :showcase_cases, dependent: :destroy
  has_many :mentor_answers, dependent: :destroy

  # Internal codes stay T/I/P/S; UI always uses Chinese labels for 基层用户.
  TIPS_STAGES = %w[T I P S].freeze

  # 面向农业基层的中文阶段名（短标签，用于筛选/列表/大字展示）
  TIPS_STAGE_LABELS = {
    "T" => "起步期",
    "I" => "成长期",
    "P" => "壮大期",
    "S" => "示范期"
  }.freeze

  # 一句话说明，便于农户理解自己处在哪一档
  TIPS_STAGE_HINTS = {
    "T" => "刚起步，正在打基础、学技术",
    "I" => "加大投入，经营在往上走",
    "P" => "规模扩大，发展比较稳",
    "S" => "示范带动，经验能帮到乡亲"
  }.freeze

  validates :phone, :name, presence: true
  validates :phone, uniqueness: true, format: { with: /\A1\d{10}\z/, message: "must be 11-digit CN mobile" }
  validates :tips_stage, inclusion: { in: TIPS_STAGES }

  scope :in_district, ->(district_id) { where(district_id: district_id) }

  def self.tips_stage_label(code)
    TIPS_STAGE_LABELS[code.to_s] || code.to_s
  end

  def self.tips_stage_hint(code)
    TIPS_STAGE_HINTS[code.to_s] || ""
  end

  # [[label, code], ...] for selects — value is still T/I/P/S
  def self.tips_stage_options
    TIPS_STAGES.map { |code| [ tips_stage_label(code), code ] }
  end

  def tips_stage_label
    self.class.tips_stage_label(tips_stage)
  end

  def tips_stage_hint
    self.class.tips_stage_hint(tips_stage)
  end

  def tips_stage_display
    "#{tips_stage_label}"
  end

  def unread_message_count
    app_messages.where(read_at: nil).count
  end

  def tag_names
    tags.pluck(:name)
  end

  def assign_tags!(tag_ids, user_corrected: false)
    Array(tag_ids).each do |tid|
      st = student_tags.find_or_initialize_by(tag_id: tid)
      st.user_corrected = user_corrected if user_corrected
      st.save!
    end
  end

  def correct_tags!(tag_ids)
    transaction do
      student_tags.where.not(tag_id: tag_ids).destroy_all
      assign_tags!(tag_ids, user_corrected: true)
    end
  end
end
