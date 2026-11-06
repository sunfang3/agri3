# frozen_string_literal: true

demo_multiplier.times do |batch|
  city_mentor = mentors.keep demo_label(:city_mentor, batch), unique_by: :name,
    name: batch.zero? ? "市农广校教研室" : "市农广校#{demo_topic(batch)}教研组#{batch + 1}",
    specialty: "高素质农民培育 · #{demo_topic(batch)}", phone: format("139%08d", batch * 9), deep_tags: [ "市直" ]
  local_mentors = MENTOR_SPECS.map.with_index.to_h do |spec, index|
    name = batch.zero? ? spec[:name] : "#{%w[李 吴 郑 冯 蒋 钱 卫][(batch - 1) % 7]}#{%w[耕 穗 园 禾 苗 丰 林 果][index]}农#{batch > 7 ? batch : ''}"
    mentor = mentors.keep demo_label(:mentor, batch * 8 + index), unique_by: :name,
      name: name, specialty: spec[:specialty], district: districts.public_send(spec[:code]),
      phone: format("139%08d", batch * 9 + index + 1), deep_tags: [ spec[:specialty] ]
    [ spec[:code], mentor ]
  end

  (CITY_POLICY_SPECS + LOCAL_POLICY_SPECS).each_with_index do |spec, index|
    district = spec[:code] ? districts.public_send(spec[:code]) : nil
    title = "#{spec[:title]}#{demo_suffix(batch)}"
    policy = policies.keep demo_label(:policy, batch * 9 + index), unique_by: :title,
      title: title, content_text: "#{spec[:content]}\n【演示数据】#{demo_topic(batch)}专题，用于系统功能演示。",
      valid_until: Date.new([ demo_reference_date.year + 1, 2027 ].max, 12, 31), district: district,
      parse_status: batch.zero? ? (district ? "manual" : "approved") : %w[approved manual pending_review][batch % 3]
    policy.tags = (spec[:tag_keys] || spec[:tags]).map { |label| tags.public_send(label) } if policy.previously_new_record?
    attributes = {}
    attributes[:document_number] = "演示农广〔#{demo_reference_date.year}〕#{format('%03d', batch * 9 + index + 1)}号" if policy.document_number.blank?
    attributes[:issuing_authority] = district ? "#{district.name}农业农村部门（演示）" : "济南市农广校（演示）" if policy.issuing_authority.blank?
    attributes[:pdf_text] = policy.content_text if policy.pdf_text.blank?
    attributes[:parsed_fields] = { "detected_title" => title, "keywords" => [ demo_topic(batch) ] } if policy.parsed_fields.blank?
    policy.update!(attributes) if attributes.any?
  end

  COURSE_SPECS.each_with_index do |spec, index|
    city = spec[:kind] == :city_direct
    district = city ? nil : districts.public_send(spec[:code])
    mentor = city ? city_mentor : local_mentors.fetch(spec[:mentor])
    latitude, longitude = COORDINATES.fetch(city ? "lixia" : spec[:code])
    day = batch.zero? ? demo_reference_date + spec[:days].days : demo_reference_date.advance(months: [ 0, -6, -5, -4, -3, -2, -1, 1 ][batch % 8]) + index.days
    course = courses.keep demo_label(:course, batch * COURSE_SPECS.size + index), unique_by: :title,
      title: "#{spec[:title]}#{demo_suffix(batch)}", description: spec[:description] || "【演示课程】#{spec[:title]} · #{demo_topic(batch)}",
      district: district, mentor: mentor, mentor_name: mentor.name, place: spec[:place],
      starts_at: day.in_time_zone.change(hour: 9), ends_at: (day + 1.day).in_time_zone.change(hour: 17),
      latitude: latitude, longitude: longitude, deep_tags: spec[:tags].map(&:to_s)
    course.tags = spec[:tags].map { |label| tags.public_send(label) } if course.previously_new_record?
    course.update!(capacity: [ [ 40, 60, 80 ][index % 3], course.occupied_seats ].max) if course.capacity.nil?
  end

  ARTICLE_SPECS.each_with_index do |(title, category, body), index|
    knowledge_articles.keep demo_label(:article, batch * ARTICLE_SPECS.size + index), unique_by: :title,
      title: "#{title}#{demo_suffix(batch)}", category: category, body: "#{body}\n#{demo_topic(batch)}专题演示。", published: true
  end

  %w[pre_training daily post_exam].each_with_index do |type, index|
    title = { "pre_training" => "训前需求调查（小麦班）", "daily" => "训中日评（小麦班）", "post_exam" => "训后考试（小麦班）" }.fetch(type)
    surveys.keep demo_label(:survey, batch * 3 + index), unique_by: :title,
      title: "#{title}#{demo_suffix(batch)}", survey_type: type,
      course: type == "pre_training" && batch.positive? ? nil : demo_course(batch, 3),
      questions: type == "post_exam" ? [ { "id" => "q1", "text" => "小麦拔节期水肥管理要点？", "correct" => "控旺促壮" }, { "id" => "q2", "text" => "节水灌溉优先方式？", "correct" => "滴灌" } ] : [ { "id" => "need", "text" => type == "daily" ? "今日收获" : "最希望学习的内容" } ]
  end
end

courses.label city_demonstration: courses.course_000, city_brand: courses.course_001, licheng_wheat: courses.course_003
