class Views::AdminApp::EnrollmentReview < Views::Base
  def initialize(city_admin:, pending_enrollments:, pending_district_acks:, district_courses_readonly:)
    @city_admin = city_admin
    @pending_enrollments = pending_enrollments
    @pending_district_acks = pending_district_acks
    @district_courses_readonly = district_courses_readonly
  end

  def view_template
    div(class: "stack mt") do
      render_bulk_confirm
      render_district_acks unless @city_admin
      render_city_readonly_district_courses if @city_admin
    end
  end

  private

  def render_bulk_confirm
    section(class: "card bg-base-100 shadow") do
      div(class: "card-body") do
        h2(class: "card-title text-lg") { "待我审核录取" }
        p(class: "text-xs opacity-60 -mt-2 mb-2") do
          if @city_admin
            "市级录取：仅市直班。区办班见下方「只读」列表，不可在此确认。"
          else
            "区县录取：仅本区开办的班。本区学员报的市直班请到「知会/备案」处理，不可在此录取。"
          end
        end
        Form(url: admin_bulk_confirm_enrollments_path, method: :post, scope: false) do |f|
          ul(class: "space-y-2 mb-3", data: { testid: "pending-enrollments" }) do
            @pending_enrollments.each do |e|
              li(class: "flex items-center gap-2") do
                input(type: "checkbox", name: "enrollment_ids[]", value: e.id, class: "checkbox checkbox-sm", checked: true)
                span(class: "text-sm") do
                  plain "#{e.student.name}（#{e.student.district.name}）→ #{e.course.title} "
                  span(class: "badge badge-ghost badge-sm") { e.course.ownership_label }
                  plain " · #{e.status}"
                end
              end
            end
          end
          if @pending_enrollments.any?
            f.submit(:primary, class: "btn-sm") { "批量确认录取" }
          else
            p(class: "text-sm opacity-60") { "暂无待你审核录取的报名" }
          end
        end
      end
    end
  end

  def render_district_acks
    section(class: "card bg-base-100 shadow border border-info/30") do
      div(class: "card-body") do
        h2(class: "card-title text-lg") { "市直班 · 知会 / 备案" }
        p(class: "text-xs opacity-60 -mt-2 mb-2") do
          "本区学员报名市直班后，市级负责录取；区县仅做知会与备案，不代替市级批准。"
        end
        Form(url: admin_bulk_ack_enrollments_path, method: :post, scope: false) do |f|
          ul(class: "space-y-2 mb-3", data: { testid: "pending-district-acks" }) do
            @pending_district_acks.each do |e|
              li(class: "flex items-center gap-2") do
                input(type: "checkbox", name: "enrollment_ids[]", value: e.id, class: "checkbox checkbox-sm", checked: true)
                span(class: "text-sm") do
                  plain "#{e.student.name} → #{e.course.title} "
                  span(class: "badge badge-info badge-sm") { "市直班" }
                  plain " · 录取状态 #{e.status}"
                end
              end
            end
          end
          if @pending_district_acks.any?
            f.submit(:primary, class: "btn-sm btn-info") { "批量知会/备案" }
          else
            p(class: "text-sm opacity-60") { "暂无待备案的市直班报名" }
          end
        end
      end
    end
  end

  def render_city_readonly_district_courses
    section(class: "card bg-base-100 shadow border border-warning/30") do
      div(class: "card-body") do
        h2(class: "card-title text-lg") { "区办班报名（只读）" }
        p(class: "text-xs opacity-60 -mt-2 mb-2") do
          "各区开办班级的报名由开班区县审核录取。市级可查看，不可在此批量确认。"
        end
        if @district_courses_readonly.any?
          div(class: "overflow-x-auto", data: { testid: "district-courses-readonly" }) do
            table(class: "table table-sm") do
              thead do
                tr { %w[学员 学员区县 课程 开班区 录取状态 区备案].each { |h| th { h } } }
              end
              tbody do
                @district_courses_readonly.each do |e|
                  tr do
                    td { e.student.name }
                    td { e.student.district.name }
                    td { e.course.title }
                    td { e.course.district&.name.to_s }
                    td { e.status }
                    td { e.district_ack_status }
                  end
                end
              end
            end
          end
        else
          p(class: "text-sm opacity-60") { "暂无区办班报名记录" }
        end
      end
    end
  end
end
