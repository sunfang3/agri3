class Views::AdminApp::Workspace < Views::WorkspaceBase
  def initialize(admin:, page:, students: nil, student: nil, filter: {}, query: "")
    @admin, @page, @student, @filter, @query = admin, page, student, filter, query
    @students = students || admin.scoped_students
    @scope = admin.scoped_students
    @enrollments = admin.scoped_enrollments
  end

  def view_template
    case @page
    when :dashboard then dashboard
    when :students then students
    when :student then student_detail
    when :cockpit then cockpit
    when :resources then resources
    end
  end

  private

  def dashboard
    heading(@admin.city_admin? ? "市级管理后台 · 全市汇总视图" : "区县管理后台 · #{@admin.district.name}", "全过程培育管理 / 区县协同 / 资源精准配置") do
      div(class: "actions") { action("导入学员", new_admin_import_path); action("导出学员", admin_export_students_path, primary: true) }
    end
    kpis({ "在册学员" => @scope.count, "待我审核录取" => @enrollments.pending.count, "已录取报名" => @enrollments.enrolled.count, "已结业报名" => @enrollments.where(status: "completed").count })
    div(class: "g2") do
      panel("区县学员规模对比") { bar_chart(@scope.joins(:district).group("districts.name").count) }
      panel("成长阶段分布") { bar_chart(@scope.group(:tips_stage).count.transform_keys { |code| ::Student.tips_stage_label(code) }) }
    end
    div(class: "workspace-columns mt") do
      div(class: "stack") do
        panel("区县综合概览") do
          data_table(%w[区县 学员数 已录取 已结业 待响应需求]) do
            visible_districts.each do |district|
              ids = @scope.where(district: district).select(:id)
              enrollments = Enrollment.where(student_id: ids)
              tr do
                td { a(href: admin_students_path(district_id: district.id), class: "link") { district.name } }
                td { @scope.where(district: district).count.to_s }
                td { enrollments.enrolled.count.to_s }
                td { enrollments.where(status: "completed").count.to_s }
                td { StudentNeed.where(student_id: ids, status: "pending").count.to_s }
              end
            end
          end
        end
        panel("报名状态月度分布") do
          records = Enrollment.where(student_id: @scope.select(:id)).order(:created_at).to_a
          months = records.group_by { |e| e.created_at.to_s.first(7) }.to_a.last(10).to_h
          empty if records.empty?
          bar_chart(months.transform_values(&:size)) if records.any?
        end
      end
      aside(class: "stack") do
        panel("今日操作清单") do
          list_row("报名审核", "#{@enrollments.pending.count} 条待处理") { action("进入", admin_students_path) }
          list_row("需求跟进", "#{StudentNeed.where(student: @scope, status: 'pending').count} 条待响应") { action("查看", admin_students_path) }
          list_row("荣誉审核", "#{Honor.where(student: @scope, status: 'pending').count} 条待审核") { action("查看", admin_students_path) }
          action("精准匹配驾驶舱", admin_cockpit_path, primary: true)
        end
        panel("实时动态") do
          events = AnalyticsEvent.where(district_code: visible_districts.select(:code)).order(id: :desc).limit(10)
          events = AnalyticsEvent.order(id: :desc).limit(10) if @admin.city_admin?
          events.each { |e| list_row(event_label(e), date_label(e.created_at)) }
          empty("暂无动态") if events.empty?
        end
        panel("区县管理员账户") do
          admins = Admin.where(district: visible_districts)
          admins.each { |a| list_row(a.name, "#{a.district&.name} · #{a.email}") }
          empty if admins.empty?
        end
      end
    end
    render_review
  end

  def students
    heading("学员档案 · 审核录取", @admin.city_admin? ? "全市学员档案；市直班录取与区办班只读分离" : "本区学员画像；区办班录取与市直班备案分离") do
      div(class: "actions") { action("Excel 批量导入", new_admin_import_path); action("导出学员", admin_export_students_path, primary: true) }
    end
    kpis({ "筛选学员" => @students.count, "待录取" => @enrollments.pending.count, "待备案" => @admin.pending_district_acks.count, "待响应需求" => StudentNeed.where(student: @scope, status: "pending").count })
    div(class: "stack") do
      panel("#{@admin.city_admin? ? '全市' : '本区'}学员画像", subtitle: "多维筛选 · 点击姓名查看完整档案") do
        Form(url: admin_students_path, method: :get, scope: false, class: "filters") do
          input(name: "q", value: @filter["q"], class: "field", placeholder: "搜索姓名 / 手机号", aria_label: "搜索学员")
          select(name: "district_id", class: "field", aria_label: "区县") do
            option(value: "") { "全部可见区县" }
            visible_districts.each { |d| option(value: d.id, selected: @filter["district_id"].to_s == d.id.to_s) { d.name } }
          end
          select(name: "stage", class: "field", data: { testid: "filter-stage" }, aria_label: "成长阶段") do
            option(value: "") { "全部成长阶段" }
            ::Student.tips_stage_options.each { |label, value| option(value: value, selected: @filter["stage"] == value) { label } }
          end
          select(name: "tag_id", class: "field", data: { testid: "filter-tag" }, aria_label: "匹配标签") do
            option(value: "") { "全部标签" }
            Tag.order(:name).each { |t| option(value: t.id, selected: @filter["tag_id"].to_s == t.id.to_s) { t.name } }
          end
          select(name: "enrollment_status", class: "field", data: { testid: "filter-enrollment" }, aria_label: "报名状态") do
            option(value: "") { "全部报名状态" }
            { "pending" => "审核中", "enrolled" => "已录取", "completed" => "已结业", "dropped" => "已取消" }.each { |value, label| option(value: value, selected: @filter["enrollment_status"] == value) { label } }
          end
          button(type: "submit", class: "tbtn pri") { "筛选" }
        end
        data_table(%w[姓名 手机号 区县 成长阶段 主业 匹配标签 操作]) do
          @students.includes(:district, :tags).limit(200).each do |s|
            tr do
              td { a(href: admin_student_path(s), class: "link") { s.name } }
              td { s.phone }; td { s.district.name }; td { chip(s.tips_stage_label) }
              td { s.primary_industry.to_s }; td { s.tags.each { |t| chip(t.name, "dim") } }
              td { action("档案", admin_student_path(s)) }
            end
          end
        end
        empty("没有符合条件的学员") if @students.empty?
        p(class: "muted mt") { "当前显示前 200 条，使用筛选定位学员；完整数据可导出。" } if @students.count > 200
      end
      render_review
      panel("案例展示墙") do
        cases = ShowcaseCase.published.where(student: @scope).includes(:student).limit(8)
        cases.each { |c| list_row(c.title, "#{c.student.name} · 贡献分 #{c.contribution_score}") }
        empty("暂无已发布案例") if cases.empty?
      end
    end
  end

  def student_detail
    heading(@student.name, "#{@student.district.name} · #{@student.phone} · #{@student.tips_stage_label}") { action("返回学员档案", admin_students_path) }
    kpis(Presentation::StudentRecord.new(@student).metrics)
    div(class: "g2") do
      div(class: "stack") do
        panel("需求与意向 · 跟进") do
          @student.student_needs.order(id: :desc).each do |need|
            list_row(need.body, need.status_label)
            Form(url: admin_need_path(need), method: :patch, scope: false, class: "form-stack") do
              label(class: "form-label") { span { "跟进回复" }; textarea(name: "student_need[response]", class: "field") { need.response.to_s } }
              select(name: "student_need[status]", class: "field", aria_label: "需求状态") do
                { "pending" => "待响应", "processing" => "处理中", "responded" => "已响应" }.each { |v, label| option(value: v, selected: need.status == v) { label } }
              end
              button(type: "submit", class: "tbtn pri") { "保存跟进" }
            end
          end
          empty("暂无需求") if @student.student_needs.empty?
        end
        panel("荣誉审核") do
          @student.honor_records.with_attached_evidence.order(id: :desc).each do |honor|
            list_row(honor.title, "#{date_label(honor.awarded_on)} · #{honor.status_label}") do
              div(class: "actions") do
                action("查看材料", url_for(honor.evidence)) if honor.evidence.attached?
                button_to "通过", admin_honor_path(honor, status: "approved"), method: :patch, class: "tbtn pri"
                button_to "退回", admin_honor_path(honor, status: "rejected"), method: :patch, class: "tbtn"
              end
            end
          end
          empty("暂无荣誉申请") if @student.honor_records.empty?
        end
        panel("政策申报跟踪") do
          @student.policy_interactions.where.not(application_status: "none").includes(:policy).each do |i|
            list_row(i.policy.title, i.status_label) do
              if i.application_status == "applied"
                div(class: "actions") do
                  button_to "登记获批", admin_policy_interaction_path(i, status: "approved"), method: :patch, class: "tbtn pri"
                  button_to "未获批", admin_policy_interaction_path(i, status: "rejected"), method: :patch, class: "tbtn"
                end
              end
            end
          end
        end
        panel("作品展示审核") do
          @student.showcase_cases.with_attached_media.each do |showcase|
            list_row(showcase.title, showcase.body) do
              div(class: "actions") do
                action("查看作品", url_for(showcase.media)) if showcase.media.attached?
                button_to(showcase.published? ? "撤下展示" : "审核并发布", admin_showcase_path(showcase, published: showcase.published? ? "0" : "1"), method: :patch, class: "tbtn pri")
              end
            end
          end
          empty("暂无作品") if @student.showcase_cases.empty?
        end
        panel("导师与服务答疑") do
          @student.mentor_answers.order(id: :desc).each do |answer|
            list_row(answer.question, answer.answer_text.presence || "待答复")
            Form(url: admin_mentor_answer_path(answer), method: :patch, scope: false, class: "form-stack") do
              label(class: "form-label") { span { "答复内容" }; textarea(name: "answer_text", required: true, maxlength: 5000, class: "field") { answer.answer_text.to_s } }
              button(type: "submit", class: "tbtn pri") { "答复学员" }
            end
          end
          empty("暂无提问") if @student.mentor_answers.empty?
        end
      end
      div(class: "stack") do
        panel("基础画像与学习记录") do
          list_row("主营产业", @student.primary_industry)
          list_row("经营规模", @student.scale)
          list_row("年收入", @student.annual_income)
          @student.tags.each { |t| chip(t.name) }
          Presentation::StudentRecord.new(@student).archive.first(15).each { |r| list_row(r[:title], "#{r[:type]} · #{r[:detail]}") }
        end
        panel("记录六维能力评估", subtitle: "仅录入有依据的测评结果，0–100 分") do
          Form(url: admin_student_assessments_path(@student), method: :post, scope: false, class: "form-stack") do
            text_field("assessment[assessed_on]", "评估日期", type: "date", value: Date.current, required: true)
            div(class: "form-grid") do
              CapabilityAssessment::DIMENSIONS.each { |key, label| text_field("assessment[scores][#{key}]", label, type: "number", min: 0, max: 100, step: "any", required: true) }
            end
            button(type: "submit", class: "tbtn pri") { "保存能力评估" }
          end
          @student.capability_assessments.order(assessed_on: :desc).each { |a| list_row(date_label(a.assessed_on), "综合均分 #{a.average_score}") }
        end
      end
    end
  end

  def cockpit
    heading("精准匹配驾驶舱", "画像与资源供给的连接，基于真实记录观察培育效果") do
      div(class: "actions") { action("刷新数据", admin_cockpit_path); action("导出学员", admin_export_students_path) }
    end
    matches = ResourceMatch.where(student: @scope)
    interactions = PolicyInteraction.where(student: @scope)
    kpis({ "学员总数" => @scope.count, "平均匹配度" => matches.average(:score)&.to_f&.round(1), "政策已查看" => interactions.where.not(viewed_at: nil).count, "政策已获批" => interactions.where(application_status: "approved").count })
    div(class: "g2") do
      div(class: "stack") do
        panel("学员需求词云", subtitle: "学员主动提交的需求") do
          needs = StudentNeed.where(student: @scope).order(id: :desc).limit(20)
          div(class: "cloud") { needs.each { |n| span(class: "tag y") { n.body } } }
          empty("暂无需求记录") if needs.empty?
        end
        panel("政策触达转化漏斗", subtitle: "匹配 → 查看 → 收藏 → 申报 → 获批") do
          bar_chart({ "已匹配" => matches.policies.count, "已查看" => interactions.where.not(viewed_at: nil).count, "已收藏" => interactions.where(saved: true).count, "已申报" => interactions.where.not(application_status: "none").count, "已获批" => interactions.where(application_status: "approved").count })
        end
        panel("政策 × 区县 · 匹配热力图", subtitle: "各区县匹配人数") do
          policies = Policy.published.limit(8)
          districts = visible_districts.to_a
          counts = matches.policies.joins(student: :district).group(:matchable_id, "districts.id").count
          max = counts.values.max.to_f
          data_table([ "政策" ] + districts.map(&:name)) do
            policies.each do |p|
              tr do
                th { p.title }
                districts.each do |d|
                  count = counts.fetch([ p.id, d.id ], 0)
                  td { span(class: "heat-cell", style: "--heat:#{max.positive? ? 0.1 + count / max * 0.8 : 0.1}") { count.to_s } }
                end
              end
            end
          end
        end
        panel("能力成长曲线", subtitle: "每月已记录评估的平均分") do
          records = CapabilityAssessment.where(student: @scope).order(:assessed_on).to_a
          empty("暂无能力评估") if records.empty?
          render Components::Ui::GrowthChart.new(values: records.group_by { |r| r.assessed_on.strftime("%Y-%m") }.transform_values { |rows| (rows.sum(&:average_score) / rows.size).round(1) }) if records.any?
        end
      end
      div(class: "stack") do
        panel("最新政策入库") { Policy.order(id: :desc).limit(5).each { |p| list_row(p.title, "#{p.issuing_authority} · #{date_label(p.created_at)}") }; action("政策资源库", admin_resources_path) }
        panel("服务供给热度", subtitle: "课程报名次数") do
          counts = Enrollment.where(student: @scope).joins(:course).group("courses.title").count.sort_by { |_, count| -count }.first(8).to_h
          empty("暂无报名记录") if counts.empty?
          bar_chart(counts)
        end
        panel("全市学员能力分布", subtitle: "每人最近一次六维评估均分") do
          latest = CapabilityAssessment.where(student: @scope).order(:assessed_on, :id).to_a.group_by(&:student_id).values.map(&:last)
          bar_chart({ "80–100 分" => latest.count { |a| a.average_score >= 80 }, "60–79 分" => latest.count { |a| a.average_score >= 60 && a.average_score < 80 }, "60 分以下" => latest.count { |a| a.average_score < 60 }, "尚未评估" => @scope.count - latest.size })
        end
        panel("资源缺口分析 / 预警中心") do
          gaps = ResourceGap.where(district_id: visible_districts.select(:id))
          gaps = gaps.or(ResourceGap.where(district_id: nil)) if @admin.city_admin?
          gaps = gaps.order(id: :desc).limit(8)
          gaps.each { |g| list_row(g.title, "需求 #{g.demand_count} · 供给 #{g.supply_count}") }
          alerts = ::Alert.open_alerts.where(district_id: visible_districts.select(:id))
          alerts = alerts.or(::Alert.open_alerts.where(district_id: nil)) if @admin.city_admin?
          alerts = alerts.limit(8)
          alerts.each { |a| list_row(a.title, a.body) { chip(a.severity, "r") } }
          empty("暂无资源缺口和预警") if gaps.empty? && alerts.empty?
        end
        engine_panel
      end
    end
  end

  def resources
    heading("政策资源库 · 标签管理", "政策要素、课程资源与匹配标签统一管理") do
      div(class: "actions") { action("新建政策", new_admin_policy_path, primary: true); action("新建课程", new_admin_course_path) }
    end
    kpis({ "已发布政策" => Policy.published.count, "可见课程" => @admin.scoped_courses.count, "匹配标签" => Tag.count, "待校对政策" => Policy.where(parse_status: "pending_review").count })
    div(class: "workspace-columns") do
      div(class: "stack") do
        panel("政策库 Policies") do
          Form(url: admin_resources_path, method: :get, scope: false, class: "filters") do
            input(name: "q", value: @query, class: "field", placeholder: "搜索标题 / 文号", aria_label: "搜索政策")
            button(type: "submit", class: "tbtn pri") { "检索" }
          end
          policies = Policy.includes(:tags).order(id: :desc)
          if @query.present?
            q = "%#{Policy.sanitize_sql_like(@query)}%"
            policies = policies.where("title LIKE ? OR document_number LIKE ?", q, q)
          end
          data_table([ "政策 / 文号", "发布单位", "截止日期", "标签", "解析状态", "操作" ]) do
            policies.limit(100).each do |p|
              tr do
                td { strong { p.title }; p(class: "muted") { p.document_number.to_s } }
                td { p.issuing_authority.to_s }; td { date_label(p.valid_until) }
                td { p.tags.each { |t| chip(t.name) } }; td { { "manual" => "手工录入", "pending_review" => "待校对", "approved" => "已校对" }.fetch(p.parse_status, p.parse_status) }
                td do
                  div(class: "actions") do
                    action("编辑", edit_admin_policy_path(p))
                    button_to "解析", parse_pdf_admin_policy_path(p), method: :post, class: "tbtn"
                    action("校对", edit_admin_policy_path(p)) if p.parse_status == "pending_review"
                  end
                end
              end
            end
          end
          empty("没有符合条件的政策") if policies.empty?
        end
        panel("资源标签库") do
          div(class: "g3") do
            Tag.order(:category, :name).group_by(&:category).each do |category, tags|
              div(class: "card") do
                div(class: "card-h") { h3 { category } }
                div(class: "card-b actions") { tags.each { |t| chip("#{t.name} · #{t.students.count}") } }
              end
            end
          end
          if @admin.city_admin?
            Form(url: admin_tags_path, method: :post, scope: false, class: "filters mt") do
              input(name: "tag[name]", class: "field", required: true, placeholder: "新标签名称", aria_label: "新标签名称")
              select(name: "tag[category]", class: "field", aria_label: "标签分类") do
                Tag::CATEGORIES.each { |category| option(value: category) { category } }
              end
              button(type: "submit", class: "tbtn pri") { "添加标签" }
            end
            details(class: "mt") do
              summary(class: "tbtn") { "编辑已有标签" }
              Tag.order(:category, :name).each do |tag|
                Form(url: admin_tag_path(tag), method: :patch, scope: false, class: "filters mt") do
                  chip(tag.category)
                  input(name: "tag[name]", class: "field", value: tag.name, required: true, aria_label: "标签名称")
                  button(type: "submit", class: "tbtn") { "保存" }
                end
              end
            end
          end
        end
        panel("课程资源 Courses") do
          @admin.scoped_courses.includes(:district).limit(10).each { |c| list_row(c.title, "#{c.ownership_label} · #{c.starts_on_label}") { action("课程学员", admin_course_path(c)) } }
          action("全部课程", admin_courses_path)
        end
      end
      aside(class: "stack") do
        panel("PDF 解析与人工校对") do
          p(class: "muted") { "新建或编辑政策时填写原文，解析后逐项检查标题、正文和有效期，再确认校对。" }
          Policy.where(parse_status: "pending_review").limit(8).each { |p| list_row(p.title) { action("人工校对", edit_admin_policy_path(p)) } }
          empty("暂无待校对政策") unless Policy.exists?(parse_status: "pending_review")
        end
        panel("触达转化效果 TOP") do
          counts = PolicyInteraction.where(student: @scope, application_status: "approved").joins(:policy).group("policies.title").count
          empty("暂无获批登记") if counts.empty?
          bar_chart(counts)
        end
        engine_panel
      end
    end
  end

  def engine_panel
    panel("匹配引擎运维", subtitle: "规则匹配 / 余弦相似度") do
      matches = ResourceMatch.where(student: @scope)
      list_row("推荐记录", matches.count)
      latest = matches.order(updated_at: :desc).first
      list_row("最近更新", latest ? date_label(latest.updated_at) : "尚未运行")
      Form(url: admin_matching_path, method: :post, scope: false, class: "form-stack") do
        select(name: "engine", class: "field", aria_label: "匹配引擎") do
          option(value: "rules") { "规则匹配" }
          option(value: "cosine") { "余弦相似度" } if @admin.city_admin?
        end
        button(type: "submit", class: "tbtn pri") { "重新计算匹配" }
      end
    end
  end

  def visible_districts
    @admin.city_admin? ? District.order(:name) : District.where(id: @admin.district_id)
  end

  def render_review
    render Views::AdminApp::EnrollmentReview.new(
      city_admin: @admin.city_admin?,
      pending_enrollments: @enrollments.pending.includes(student: :district, course: :district),
      pending_district_acks: @admin.pending_district_acks.includes(student: :district, course: :district),
      district_courses_readonly: @admin.scoped_district_courses_readonly
    )
  end

  def event_label(event)
    { "course_create" => "创建课程", "course_update" => "更新课程", "submit_need" => "提交需求", "enroll" => "提交课程报名", "correct_tags" => "修正画像标签", "refresh_matching" => "刷新匹配", "policy_create" => "政策入库" }[event.action_name] || { "login" => "账号登录", "page_view" => "访问培育平台", "key_action" => "业务操作" }[event.event_type]
  end
end
