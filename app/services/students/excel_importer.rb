# frozen_string_literal: true

require "roo"

module Students
  # Excel bulk import with dry-run preview vs commit.
  # Expected columns: phone, name, district_code, primary_industry, scale, annual_income, honors
  class ExcelImporter
    HEADERS = %w[phone name district_code primary_industry scale annual_income honors].freeze

    RowResult = Struct.new(:row_number, :attrs, :errors, :action, keyword_init: true)

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
      if commit
        results.select { |r| r.errors.empty? }.each do |r|
          student = Student.find_or_initialize_by(phone: r.attrs[:phone])
          was_new = student.new_record?
          student.assign_attributes(r.attrs.except(:password))
          # Always ensure digest exists so login cannot be blank-password bypass
          if student.password_digest.blank?
            student.password = default_import_password(r.attrs[:phone])
          end
          student.save!
          was_new ? created += 1 : updated += 1
          r.action = was_new ? "created" : "updated"
        end
      else
        results.each do |r|
          next if r.errors.any?

          r.action = Student.exists?(phone: r.attrs[:phone]) ? "would_update" : "would_create"
        end
      end

      {
        dry_run: !commit,
        total: results.size,
        valid: results.count { |r| r.errors.empty? },
        invalid: results.count { |r| r.errors.any? },
        created: created,
        updated: updated,
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

      clean = {
        phone: attrs[:phone],
        name: attrs[:name],
        district_id: district&.id,
        primary_industry: attrs[:primary_industry],
        scale: attrs[:scale],
        annual_income: attrs[:annual_income],
        honors: attrs[:honors]
      }

      RowResult.new(row_number: row_number, attrs: clean, errors: errors, action: nil)
    end

    # Imported accounts get a deterministic initial password (phone) — must authenticate with it.
    def default_import_password(phone)
      phone.to_s
    end
  end
end
