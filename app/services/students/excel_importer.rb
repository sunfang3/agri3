# frozen_string_literal: true

require "roo"

module Students
  # Excel bulk import with dry-run preview vs commit.
  # Required columns: phone, name, district_code
  # Optional: primary_industry, scale, annual_income, honors, course_title
  #
  # course_title: if present and matches a published Course, creates a pending
  # Enrollment with ownership rules:
  #   市直班 (course.district_id nil) → district_ack_status pending (户籍区备案)
  #   区办班 → district_ack_status not_required (开班区录取)
  class ExcelImporter
    REQUIRED_HEADERS = %w[phone name district_code].freeze
    OPTIONAL_HEADERS = %w[primary_industry scale annual_income honors course_title].freeze
    HEADERS = (REQUIRED_HEADERS + OPTIONAL_HEADERS).freeze

    RowResult = Struct.new(:row_number, :attrs, :errors, :action, :enrollment_action, keyword_init: true)

    def initialize(file_path_or_io, filename: "import.xlsx")
      @source = file_path_or_io
      @filename = filename
    end

    def dry_run
      process(commit: false)
    end

    def commit!
      process(commit: true)
    end

    private

    def process(commit:)
      rows = parse_rows
      results = rows.map { |row_number, attrs| validate_row(row_number, attrs) }

      created = 0
      updated = 0
      enrollments_created = 0
      if commit
        results.select { |r| r.errors.empty? }.each do |r|
          student = Student.find_or_initialize_by(phone: r.attrs[:phone])
          was_new = student.new_record?
          student.assign_attributes(r.attrs.slice(
            :phone, :name, :district_id, :primary_industry, :scale, :annual_income, :honors
          ))
          if student.password_digest.blank?
            student.password = default_import_password(r.attrs[:phone])
          end
          student.save!
          was_new ? created += 1 : updated += 1
          r.action = was_new ? "created" : "updated"

          if r.attrs[:course_id].present?
            enrollment, created_enroll = enroll_student!(student, r.attrs[:course_id])
            if enrollment
              enrollments_created += 1 if created_enroll
              r.enrollment_action = enrollment_action_label(enrollment)
            end
          end
        end
      else
        results.each do |r|
          next if r.errors.any?

          r.action = Student.exists?(phone: r.attrs[:phone]) ? "would_update" : "would_create"
          if r.attrs[:course_id].present?
            course = Course.find_by(id: r.attrs[:course_id])
            r.enrollment_action =
              if course.nil?
                "course_missing"
              elsif Student.find_by(phone: r.attrs[:phone])&.enrollments&.exists?(course_id: course.id)
                "would_skip_enroll"
              else
                course.city_direct? ? "would_enroll_city_direct" : "would_enroll_district"
              end
          end
        end
      end

      {
        dry_run: !commit,
        total: results.size,
        valid: results.count { |r| r.errors.empty? },
        invalid: results.count { |r| r.errors.any? },
        created: created,
        updated: updated,
        enrollments_created: enrollments_created,
        rows: results
      }
    end

    def parse_rows
      spreadsheet = open_sheet
      header = spreadsheet.row(1).map { |h| h.to_s.strip.downcase }
      indices = HEADERS.to_h { |h| [ h, header.index(h) ] }

      (2..spreadsheet.last_row).filter_map do |i|
        raw = spreadsheet.row(i)
        next if raw.all?(&:blank?)

        attrs = {}
        HEADERS.each do |h|
          idx = indices[h]
          attrs[h.to_sym] = idx ? raw[idx] : nil
        end
        attrs[:phone] = attrs[:phone].to_s.gsub(/\D/, "")
        attrs[:name] = attrs[:name].to_s.strip
        attrs[:district_code] = attrs[:district_code].to_s.strip
        attrs[:primary_industry] = attrs[:primary_industry].to_s.strip.presence
        attrs[:scale] = attrs[:scale].presence
        attrs[:annual_income] = attrs[:annual_income].presence
        attrs[:honors] = attrs[:honors].to_s.presence
        attrs[:course_title] = attrs[:course_title].to_s.strip.presence
        [ i, attrs ]
      end
    end

    def open_sheet
      path = if @source.respond_to?(:path) && @source.path
        @source.path
      elsif @source.is_a?(String)
        @source
      else
        tmp = Tempfile.new([ "import", File.extname(@filename) ])
        tmp.binmode
        tmp.write(@source.read)
        tmp.rewind
        tmp.path
      end
      Roo::Spreadsheet.open(path)
    end

    def validate_row(row_number, attrs)
      errors = []
      errors << "phone invalid" unless attrs[:phone].to_s.match?(/\A1\d{10}\z/)
      errors << "name blank" if attrs[:name].blank?

      district = District.find_by(code: attrs[:district_code])
      errors << "district_code unknown" unless district

      course = nil
      if attrs[:course_title].present?
        course = Course.published.find_by(title: attrs[:course_title])
        errors << "course_title unknown or unpublished" unless course
      end

      clean = {
        phone: attrs[:phone],
        name: attrs[:name],
        district_id: district&.id,
        primary_industry: attrs[:primary_industry],
        scale: attrs[:scale],
        annual_income: attrs[:annual_income],
        honors: attrs[:honors],
        course_id: course&.id,
        course_title: attrs[:course_title],
        course_kind: course && (course.city_direct? ? "city_direct" : "district")
      }

      RowResult.new(row_number: row_number, attrs: clean, errors: errors, action: nil, enrollment_action: nil)
    end

    def enroll_student!(student, course_id)
      course = Course.published.find_by(id: course_id)
      return [ nil, false ] unless course

      enrollment = Enrollment.find_or_initialize_by(student: student, course: course)
      created = enrollment.new_record?
      if created
        enrollment.status = "pending"
        # before_validation assigns district_ack for city_direct
        enrollment.save!
      end
      [ enrollment, created ]
    end

    def enrollment_action_label(enrollment)
      if enrollment.course.city_direct?
        "enrolled_city_direct_ack_#{enrollment.district_ack_status}"
      else
        "enrolled_district_course"
      end
    end

    def default_import_password(phone)
      phone.to_s
    end
  end
end
