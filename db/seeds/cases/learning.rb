# frozen_string_literal: true

demo_students.each_with_index do |student, index|
  enrollment = enrollments.public_send(demo_label(:enrollment, index * 3 + 2))
  next unless enrollment.status.in?(%w[enrolled completed])

  course = enrollment.course
  note = voice_notes.with(student: student).keep demo_label(:note, index), unique_by: [ :student, :course ],
    course: course, transcript: "【演示课堂笔记】#{course.title}：记录技术要点、经营成本与下一步实践计划。",
    status: "transcribed", structured: { "topics" => [ "成本记录", "生产实践" ], "todos" => [ "记录试验田对比结果" ] }
  attach_audio(note.audio)
  photo = training_photos.keep demo_label(:photo, index), unique_by: :storage_key,
    student: student, course: course, storage_key: "demo/photos/#{student.phone}",
    latitude: course.latitude, longitude: course.longitude,
    taken_at: demo_reference_date.in_time_zone - (index % 20).days,
    watermark_text: "演示记录 · #{demo_reference_date - (index % 20).days} · #{course.place}"
  attach_example(photo.image)
  check_ins.keep demo_label(:check_in, index), unique_by: [ :enrollment, :token ],
    enrollment: enrollment, student: student, course: course, token: "demo-check-in-#{student.phone}",
    latitude: course.latitude, longitude: course.longitude, gps_valid: true, distance_meters: 0,
    checked_in_at: demo_reference_date.in_time_zone - (index % 20).days
  mentor_answers.with(student: student).keep demo_label(:question, index), unique_by: [ :student, :question ],
    mentor: course.mentor, question: "如何做好本季成本与产量对比？",
    status: index.even? ? "answered" : "open",
    answer_text: index.even? ? "划分对照田，分别记录投入、工时和产量，在培训后复盘差异。（演示答复）" : nil
  attributions.with(student: student).keep demo_label(:attribution, index), unique_by: [ :student, :matchable, :outcome_type ],
    matchable: course, outcome_type: "enrollment_complete", contribution: 1.0,
    details: { "source" => "demo_seed", "course_title" => course.title }

  batch = index / 24
  [ 0, 2 ].each do |survey_index|
    survey = surveys.public_send(demo_label(:survey, batch * 3 + survey_index))
    next if survey.course_id && !student.enrollments.exists?(course_id: survey.course_id, status: %w[enrolled completed])

    answers = survey_index.zero? ? { "need" => %w[技术实训 经营管理 政策申报 品牌营销][index % 4] } : { "q1" => "控旺促壮", "q2" => index.even? ? "滴灌" : "漫灌" }
    survey_responses.keep demo_label(:response, index * 2 + survey_index / 2), unique_by: [ :student, :survey ],
      student: student, survey: survey, answers: answers, score: survey_index == 2 ? (index.even? ? 100 : 50) : nil
  end
end
