# frozen_string_literal: true

admins.keep :city, unique_by: :email, email: "city@jinan.local", name: "济南市农广校·市级管理员", role: "city"
reference_date = demo_reference_date
industry_tags = TAG_SPECS.select { |_, category, _, _| category == "industry" }.to_h { |label, _, name, _| [ name, label ] }

District::JINAN_CODES.each_with_index do |code, district_index|
  district = districts.public_send(code)
  profile = DISTRICT_PROFILES.fetch(code)
  admins.with(district: district).keep code.to_sym, unique_by: :email,
    email: "admin@#{code}.local", name: ADMIN_NAMES.fetch(code)

  demo_multiplier.times do |batch|
    students.with(district: district) do |local_students|
      2.times do |member|
        index = batch * 24 + district_index * 2 + member
        factor = [ 1.0, 0.4, 0.65, 0.85, 1.15, 1.4, 1.8, 2.1 ][batch % 8]
        scale = (profile[:scale] * (member.zero? ? 1 : 0.55) * factor).round(1)
        income = (profile[:income] * (member.zero? ? 1 : 0.6) * factor).round
        name = "#{district.name.delete('区县')}#{member.zero? ? '示范户' : '学员'}#{index + 1}"
        name = "张三" if index == 8
        name = "李四" if index == 2
        student = local_students.keep demo_label(:student, index), unique_by: :phone,
          phone: format("138%08d", index + 1), name: name, primary_industry: profile[:industry],
          scale: scale, annual_income: income, honors: member.zero? && batch.even? ? profile[:honor] : nil
        if student.previously_new_record?
          selected = [ tags.public_send(industry_tags.fetch(profile[:industry])), tags.object_farm ]
          selected += Tag.where(category: "scale_threshold").select { |t| student.scale.to_f >= t.value.to_f }
          selected += Tag.where(category: "income_threshold").select { |t| student.annual_income.to_f >= t.value.to_f }
          student.tags = selected
        end
        if index.zero? && !student.profile&.key?("demo_reference_date")
          student.update!(profile: (student.profile || {}).merge("demo_reference_date" => reference_date.iso8601))
        end
      end
    end
  end
end

students.label zhang_san: students.student_008, li_si: students.student_002
