module Presentation
  # Computed from recorded activity; missing assessments remain missing.
  class StudentRecord
    attr_reader :student
    def initialize(student)
      @student = student
    end

    def metrics
      {
        "报名课程" => student.enrollments.count,
        "已结业课程" => student.enrollments.where(status: "completed").count,
        "已获批政策" => student.policy_interactions.where(application_status: "approved").count,
        "已审核荣誉" => student.honor_records.where(status: "approved").count
      }
    end

    def latest_assessment = student.capability_assessments.order(assessed_on: :desc, id: :desc).first
    def assessments = student.capability_assessments.order(:assessed_on, :id)

    def completeness
      fields = [ student.name, student.primary_industry, student.scale, student.annual_income, student.tags.first ]
      (fields.count(&:present?).fdiv(fields.size) * 100).round
    end

    def archive(query = "")
      rows = student.enrollments.includes(:course).map { |e| { title: e.course.title, type: "课程", detail: e.status_label, date: e.created_at, url: "/student/courses/#{e.course_id}" } }
      rows += student.voice_notes.includes(:course).map { |n| { title: n.transcript.presence || "音频笔记", type: "笔记", detail: n.course&.title, date: n.created_at, url: n.course_id ? "/student/courses/#{n.course_id}" : nil } }
      rows += student.training_photos.includes(:course).map { |p| { title: p.watermark_text.presence || "实操照片", type: "照片", detail: p.course.title, date: p.created_at, url: "/student/courses/#{p.course_id}" } }
      rows += student.survey_responses.includes(:survey).map { |r| { title: r.survey.title, type: "学情", detail: r.score ? "#{r.score} 分" : "已填写", date: r.created_at, url: "/student/surveys/#{r.survey_id}" } }
      rows.select { |r| query.blank? || [ r[:title], r[:detail] ].join.include?(query) }.sort_by { |r| r[:date].to_s }.reverse
    end
  end
end
