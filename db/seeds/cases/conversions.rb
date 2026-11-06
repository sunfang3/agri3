# frozen_string_literal: true

demo_students.each_with_index do |student, index|
  batch = index / 24
  3.times do |offset|
    policy_interactions.with(student: student).keep demo_label(:interaction, index * 3 + offset), unique_by: [ :student, :policy ],
      policy: demo_policy(batch, (index + offset) % 9), saved: offset < 2,
      viewed_at: demo_reference_date.in_time_zone - (index % 10).days,
      application_status: offset.zero? ? %w[none applied approved rejected][index % 4] : "none"
  end
  app_messages.with(student: student).keep demo_label(:welcome, index), unique_by: [ :student, :title ],
    title: "欢迎使用农创客平台", body: "专属适配清单与学习档案已生成。市直班由市级录取、所属区备案；区办班由开班区录取。", message_type: "system"
end

District::JINAN_CODES.each do |code|
  district = districts.public_send(code)
  pending = StudentNeed.where(student: Student.where(district: district), status: "pending").count
  next if pending.zero?

  gap = resource_gaps.keep code.to_sym, unique_by: [ :district, :title ],
    district: district, gap_type: "course", title: "#{district.name}待响应培训需求（演示）",
    demand_count: pending, supply_count: 0, severity: pending > 5 ? "high" : "medium",
    description: "学员主动提交需求尚未完成课程对接，用于演示跟进与资源配置。"
  alerts.keep code.to_sym, unique_by: [ :district, :title ], district: district, title: gap.title,
    source: gap, severity: gap.severity, body: gap.description, status: "open"
end
