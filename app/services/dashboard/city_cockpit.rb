# frozen_string_literal: true

module Dashboard
  # City-level aggregates. Snapshot table replaces Postgres materialized views on Litestack.
  class CityCockpit
    SNAPSHOT_TABLE = "district_stats_snapshots"

    def summary
      {
        students_total: Student.count,
        students_by_district: Student.joins(:district).group("districts.name").count,
        students_by_stage: Student.group(:tips_stage).count,
        enrollments_by_status: Enrollment.group(:status).count,
        policies_count: Policy.published.count,
        courses_count: Course.published.count,
        matches_avg_score: ResourceMatch.average(:score)&.to_f&.round(2) || 0,
        unread_messages: AppMessage.unread.count,
        open_alerts: Alert.open_alerts.count
      }
    end

    def by_industry
      Student.group(:primary_industry).count
    end

    def materialize!
      connection = ActiveRecord::Base.connection
      connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS #{SNAPSHOT_TABLE} (
          district_id INTEGER PRIMARY KEY,
          district_name TEXT NOT NULL,
          student_count INTEGER NOT NULL DEFAULT 0,
          enrolled_count INTEGER NOT NULL DEFAULT 0,
          refreshed_at TEXT
        )
      SQL
      connection.execute("DELETE FROM #{SNAPSHOT_TABLE}")

      rows = Student.joins(:district)
        .left_joins(:enrollments)
        .group("districts.id", "districts.name")
        .pluck(
          Arel.sql("districts.id"),
          Arel.sql("districts.name"),
          Arel.sql("COUNT(DISTINCT students.id)"),
          Arel.sql("COUNT(DISTINCT CASE WHEN enrollments.status = 'enrolled' THEN enrollments.id END)")
        )

      now = Time.current.utc.iso8601
      rows.each do |district_id, name, student_count, enrolled_count|
        connection.execute(
          ActiveRecord::Base.sanitize_sql_array([
            "INSERT INTO #{SNAPSHOT_TABLE} (district_id, district_name, student_count, enrolled_count, refreshed_at) VALUES (?, ?, ?, ?, ?)",
            district_id, name, student_count, enrolled_count, now
          ])
        )
      end
      true
    rescue ActiveRecord::StatementInvalid
      false
    end

    def district_stats_from_mv
      rows = ActiveRecord::Base.connection.exec_query(
        "SELECT * FROM #{SNAPSHOT_TABLE} ORDER BY student_count DESC"
      )
      rows.to_a
    rescue ActiveRecord::StatementInvalid
      Student.joins(:district).group("districts.id", "districts.name").count.map do |(id, name), count|
        { "district_id" => id, "district_name" => name, "student_count" => count, "enrolled_count" => 0 }
      end
    end
  end
end
