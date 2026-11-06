# frozen_string_literal: true

demo_students.each_with_index do |student, index|
  batch = index / 24
  group = COURSE_SPECS.each_index.map { |i| demo_course(batch, i) }
  city = group.select(&:city_direct?)
  local = group.find { |c| c.district_id == student.district_id } || group.reject(&:city_direct?)[index % 8]
  city_course = city[index % city.size]
  city_course = city.first if student.phone == "13800000009"
  if student.phone == "13800000003"
    city_course = city[1]
    local = group[3]
  end
  history = COURSE_SPECS.each_index.map { |i| demo_course(demo_multiplier > 1 ? 1 : 0, i) }.reject { |c| [ city_course.id, local.id ].include?(c.id) }
  desired = [ [ city_course, %w[pending enrolled][index % 2] ], [ local, %w[enrolled completed pending dropped][index % 4] ], [ history[index % history.size], "completed" ] ]
  desired.each_with_index do |(course, status), slot|
    status = "pending" if index.in?([ 2, 8 ]) && slot < 2
    acknowledged = course.city_direct? && status.in?(%w[enrolled completed])
    confirmed_at = status.in?(%w[enrolled completed]) ? demo_reference_date.in_time_zone - (index % 20).days : nil
    enrollments.with(student: student).keep demo_label(:enrollment, index * 3 + slot), unique_by: [ :student, :course ],
      course: course, status: status, confirmed_at: confirmed_at,
      district_ack_status: course.city_direct? ? (acknowledged ? "acked" : "pending") : "not_required",
      district_acked_at: acknowledged ? confirmed_at : nil,
      district_ack_admin: acknowledged ? admins.public_send(student.district.code) : nil
  end
end

enrollments.label zhang_city: enrollments.enrollment_024, zhang_local: enrollments.enrollment_025,
  li_city: enrollments.enrollment_006, li_cross_district: enrollments.enrollment_007
