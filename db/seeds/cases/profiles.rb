# frozen_string_literal: true

demo_students.each_with_index do |student, index|
  status = %w[pending processing responded][index % 3]
  student_needs.with(student: student).keep demo_label(:need, index), unique_by: [ :student, :body ],
    body: "希望学习#{%w[农产品电商 品牌营销 绿色防控 成本核算][index % 4]}，用于#{DISTRICT_PROFILES.fetch(student.district.code)[:industry]}经营。",
    status: status, response: status == "responded" ? "已对接#{student.district.name}培训负责人，将结合专题班安排跟进。" : nil
  honor = honors.with(student: student).keep demo_label(:honor, index), unique_by: [ :student, :title ],
    title: DISTRICT_PROFILES.fetch(student.district.code)[:honor].presence || "#{student.district.name}农创客实践示范（演示）",
    awarded_on: demo_reference_date - (index % 180 + 30).days,
    status: %w[approved pending rejected approved][index % 4]
  attach_example(honor.evidence)

  6.times do |month|
    capability_assessments.with(student: student).keep demo_label(:assessment, index * 6 + month), unique_by: [ :student, :assessed_on ],
      assessed_on: demo_reference_date.beginning_of_month.advance(months: month - 5),
      scores: CapabilityAssessment::DIMENSIONS.keys.map.with_index.to_h { |key, dim| [ key, 42 + (index * 3 + dim * 7) % 32 + month * 2 ] }
  end

  if index.even?
    title = "#{student.district.name}·#{DISTRICT_PROFILES.fetch(student.district.code)[:specialty]}典型案例#{demo_suffix(index / 24)}"
    showcase = showcase_cases.keep demo_label(:showcase, index / 2), unique_by: :title,
      title: title, student: student, district: student.district,
      body: "【演示案例】#{student.name}完成#{demo_topic(index / 24)}专题学习，记录生产经营改进过程。",
      contribution_score: 55 + (index * 3) % 44, published: (index / 24) % 3 != 2
    attach_example(showcase.media)
  end
end
