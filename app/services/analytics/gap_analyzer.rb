# frozen_string_literal: true

module Analytics
  class GapAnalyzer
    def analyze!
      gaps = []
      District.active.find_each do |district|
        student_count = district.students.count
        policy_count = Policy.published.where(district_id: [ district.id, nil ]).count
        course_count = Course.published.where(district_id: [ district.id, nil ]).count

        if student_count.positive? && policy_count.zero?
          gaps << upsert_gap(district, "policy", "政策供给不足", student_count, 0, "high")
        end
        if student_count > 10 && course_count < 2
          gaps << upsert_gap(district, "course", "课程供给不足", student_count, course_count, "medium")
        end
      end
      gaps
    end

    def raise_alerts!
      ResourceGap.where(severity: %w[high critical]).find_each do |gap|
        Alert.find_or_create_by!(
          title: "资源缺口：#{gap.title}",
          district_id: gap.district_id,
          source_type: "ResourceGap",
          source_id: gap.id,
          status: "open"
        ) do |a|
          a.body = gap.description
          a.severity = gap.severity
        end
      end
    end

    private

    def upsert_gap(district, type, title, demand, supply, severity)
      gap = ResourceGap.find_or_initialize_by(district: district, gap_type: type, title: title)
      gap.assign_attributes(
        demand_count: demand,
        supply_count: supply,
        severity: severity,
        description: "#{district.name} demand=#{demand} supply=#{supply}"
      )
      gap.save!
      gap
    end
  end
end
