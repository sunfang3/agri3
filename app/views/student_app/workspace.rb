class Views::StudentApp::Workspace < Views::WorkspaceBase
  def initialize(student:, page:, courses: nil, course: nil, policy: nil, interaction: nil, filter: {})
    @student, @page, @course, @policy, @interaction, @filter = student, page, course, policy, interaction, filter
    @record = Presentation::StudentRecord.new(student)
    @courses = courses || Course.published.includes(:district, :mentor, :tags).order(:starts_at)
    @enrollments = student.enrollments.includes(:course).index_by(&:course_id)
    @matches = student.resource_matches.includes(:matchable).ranked.to_a.select { |m| m.matchable&.published? }
  end

  def view_template
    case @page
    when :home then home
    when :profile then profile
    when :courses then courses
    when :course then course_detail
    when :policy then policy_detail
    when :achievements then achievements
    end
  end

  private

  def home
    heading("专属适配中心", "每一项政策，找到对的人；每一次学习，记录成长。")
    div(class: "hero-strip") do
      chip("#{@student.district.name} · #{@student.tips_stage_label}", "y")
      h2 { "#{@student.name}，欢迎回到您的培育空间" }
      p { @student.tips_stage_hint }
      div(class: "hero-meta") do
        { "适配政策" => @matches.count { |m| m.matchable_type == "Policy" && m.score.positive? }, "在学课程" => @enrollments.values.count { |e| e.status == "enrolled" }, "未读消息" => @student.unread_message_count }.each do |label, count|
          div { b { count.to_s }; plain "　#{label}" }
        end
      end
    end
    div(class: "workspace-columns") do
      div(class: "stack") do
        panel("推荐清单 · 智能政策目录", subtitle: "按匹配度分层 · 展示真实推荐依据") do
          Form(url: student_home_path, method: :get, scope: false, class: "filters") do
            input(name: "q", value: @filter["q"], class: "field", placeholder: "搜索政策标题、文号…", aria_label: "搜索政策")
            select(name: "tier", class: "field", aria_label: "推荐优先级") do
              option(value: "") { "全部优先级" }
              [ "强烈推荐", "建议关注", "可了解" ].each_with_index { |label, i| option(value: i + 1, selected: @filter["tier"] == (i + 1).to_s) { label } }
            end
            button(type: "submit", class: "tbtn pri") { "筛选" }
          end
          matches = @matches.select { |m| m.matchable_type == "Policy" }
          matches = matches.select { |m| m.matchable.title.include?(@filter["q"]) || m.matchable.document_number.to_s.include?(@filter["q"]) } if @filter["q"].present?
          matches = matches.select { |m| m.priority_tier.to_s == @filter["tier"] } if @filter["tier"].present?
          [ "强烈推荐", "建议关注", "可了解" ].each_with_index do |label, i|
            div(data: { priority_tier: i + 1 }, class: "tier-group") do
              h3(class: "eyebrow mt") { label }
              items = matches.select { |m| m.priority_tier == i + 1 }
              empty("暂无该层级推荐，完善画像后可获得更准确的匹配") if items.empty?
              items.each do |match|
                list_row(match.matchable.title, "#{match.matchable.issuing_authority.presence || '惠农政策'} · 截止 #{date_label(match.matchable.valid_until)}") do
                  div(class: "actions") do
                    span(class: "score #{i.zero? ? 'hi' : 'mid'}") { "#{match.score}%" }
                    action("查看政策", student_policy_path(match.matchable))
                  end
                end
                p(class: "why") { "匹配依据：#{Array(match.reason_tags).join('、').presence || '当前标签交集较少，可补充经营画像'}" }
              end
            end
          end
        end
        panel("我的课表", subtitle: "报名与录取状态实时同步") do
          @enrollments.values.first(5).each { |e| course_row(e.course) }
          empty("还没有报名课程，前往选课中心开始学习") if @enrollments.empty?
          action("进入选课中心", student_courses_path, primary: true)
        end
        panel("师资与服务大厅") do
          mentors = Mentor.where(district_id: [ nil, @student.district_id ]).limit(6)
          empty("暂无师资信息") if mentors.empty?
          mentors.each { |m| list_row(m.name, m.specialty) { action("提交咨询", "#{student_me_path}#mentor") } }
        end
      end
      aside(class: "stack") do
        panel("我的成长档案") do
          list_row("画像完整度", "已填写基础经营信息与匹配标签") { chip("#{@record.completeness}%", "g") }
          list_row("成长阶段", @student.tips_stage_hint) { chip(@student.tips_stage_label) }
          action("完善全息画像", student_me_path, primary: true)
        end
        capabilities
        need_form
        panel("通知公告") do
          messages = @student.app_messages.order(id: :desc).limit(5)
          empty("暂无通知") if messages.empty?
          messages.each { |m| list_row(m.title, date_label(m.created_at)) }
          action("全部消息", student_messages_path)
        end
      end
    end
  end

  def profile
    heading("我的 · 全息画像", "身份、需求、能力与阶段，共同构成您的成长档案。")
    div(class: "hero-strip profile-banner") do
      div(class: "profile-avatar") { @student.name.first }
      div do
        h2 { @student.name }
        p { "#{@student.district.name} · #{@student.primary_industry.presence || '待补充主业'} · #{@student.tips_stage_label}" }
        chip("画像完整度 #{@record.completeness}%", "y")
      end
    end
    div(class: "g4") do
      panel("T · 身份与基础") do
        list_row("主营产业", @student.primary_industry.presence || "待补充")
        list_row("经营规模", @student.scale ? @student.scale.to_s : "待补充")
        list_row("年收入", @student.annual_income ? "#{@student.annual_income} 元" : "待补充")
        list_row("所在区县", @student.district.name)
      end
      panel("I · 需求与意向") do
        needs = @student.student_needs.order(id: :desc).limit(5)
        empty("提交需求，让管理员了解您需要的帮助") if needs.empty?
        needs.each { |n| list_row(n.body, n.response) { chip(n.status_label, "y") } }
        action("提交新需求", "#needs")
      end
      capabilities("P · 能力与绩效")
      panel("S · 状态与阶段") do
        div(data: { testid: "tips-stage" }, class: "k-val") { @student.tips_stage_label }
        p(class: "why mt", data: { testid: "tips-stage-hint" }) { @student.tips_stage_hint }
        p(class: "muted mt") { "阶段由经营规模、收入及配置规则综合判定，更新画像后自动重算。" }
        action("查看我的推荐", student_home_path)
      end
    end
    div(class: "g2 mt") do
      div(class: "stack") do
        panel("我的匹配标签 · 编辑画像", id: "edit-profile") do
          render StudentProfileForm.new(model: @student, url: student_me_path, method: :patch, tags: Tag.order(:category, :name))
        end
        need_form
      end
      div(class: "stack") do
        archive
        honors
        panel("导师答疑", id: "mentor") do
          Form(url: student_mentor_answers_path, method: :post, scope: false, class: "form-stack") do
            label(class: "form-label") { span { "描述您的问题" }; textarea(name: "question", class: "field", required: true, maxlength: 2000) }
            button(type: "submit", class: "tbtn pri") { "提交答疑" }
          end
          @student.mentor_answers.order(id: :desc).limit(5).each { |a| list_row(a.question, a.answer_text.presence || "等待导师答复") }
        end
      end
    end
  end

  def courses
    heading("课程 · 选学主阵地", "选课中心 / 日历课表 / 现场记录 / 学情调查")
    div(class: "workspace-columns") do
      div(class: "stack") do
        panel("选课中心", subtitle: "市直班与区县班 · 录取权跟随开班主体") do
          Form(url: student_courses_path, method: :get, scope: false, class: "filters") do
            input(name: "q", value: @filter["q"], class: "field", placeholder: "搜索课程 / 导师 / 产业…", aria_label: "搜索课程")
            select(name: "ownership", class: "field", aria_label: "开班主体") do
              [ [ "全部类型", "" ], [ "市直班", "city" ], [ "区县班", "district" ] ].each { |label, value| option(value: value, selected: @filter["ownership"] == value) { label } }
            end
            input(name: "year", value: @filter["year"], class: "field", type: "number", placeholder: "开班年度", aria_label: "开班年度", min: 2000, max: 2100)
            button(type: "submit", class: "tbtn pri") { "筛选" }
          end
          empty("没有符合条件的课程") if @courses.empty?
          @courses.each { |course| course_row(course) }
        end
        calendar
        archive
      end
      aside(class: "stack") do
        panel("报名状态统计") do
          counts = @enrollments.values.group_by(&:status).transform_values(&:size)
          bar_chart({ "审核中" => counts.fetch("pending", 0), "已录取" => counts.fetch("enrolled", 0), "已结业" => counts.fetch("completed", 0), "已取消" => counts.fetch("dropped", 0) })
        end
        panel("学情调查") do
          surveys = Survey.active.where(course_id: [ nil ] + @enrollments.keys).limit(5)
          empty("暂无可填写问卷") if surveys.empty?
          surveys.each { |s| list_row(s.title, { "pre_training" => "训前需求", "daily" => "训中日评", "post_exam" => "训后考试" }[s.survey_type]) { action("进入", student_survey_path(s)) } }
        end
        panel("推荐课程", subtitle: "根据画像标签匹配") do
          matches = @matches.select { |m| m.matchable_type == "Course" }.first(5)
          empty("暂无推荐课程") if matches.empty?
          matches.each { |m| list_row(m.matchable.title, "匹配度 #{m.score}% · #{Array(m.reason_tags).join('、')}") { action("详情", student_course_path(m.matchable)) } }
        end
      end
    end
  end

  def course_row(course)
    enrollment = @enrollments[course.id]
    match = @matches.find { |m| m.matchable_type == "Course" && m.matchable_id == course.id }
    list_row(course.title, "#{course.ownership_label} · #{course.mentor_display} · #{course.time_range_label} · #{course.place}") do
      div(class: "actions") do
        chip("#{match.score}% 匹配", "y") if match
        if enrollment
          span(class: "tag #{enrollment.status == 'enrolled' ? 'g' : ''}", data: { testid: "enrollment-status-#{course.id}" }) { enrollment.status_label }
        elsif course.full?
          chip("名额已满", "r")
        else
          button_to "报名", student_enrollments_path(course_id: course.id), method: :post, class: "tbtn pri"
        end
        action("详情", student_course_path(course))
      end
    end
    p(class: "why") { "#{course.capacity ? "已录取 #{course.occupied_seats} / #{course.capacity} 人" : '未设置人数上限'} · #{course.tags.map(&:name).join(' / ')}" }
  end

  def course_detail
    heading(@course.title, "#{@course.ownership_label} · #{@course.mentor_display}") { action("返回选课中心", student_courses_path) }
    div(class: "workspace-columns") do
      div(class: "stack") do
        panel("课程详情") do
          p(class: "rich-text") { @course.description.presence || "课程介绍待补充" }
          list_row("上课时间", @course.time_range_label)
          list_row("培训地点", @course.place)
          course_row(@course)
        end
        enrollment = @enrollments[@course.id]
        if enrollment&.status.in?(%w[enrolled completed])
          panel("现场全息记录", subtitle: "考勤 · 实操照片 · 学习笔记") do
            Form(url: student_check_ins_path, method: :post, scope: false, class: "form-stack", data: { controller: "check-in" }) do
              input(type: "hidden", name: "course_id", value: @course.id)
              text_field("token", "签到码（由培训管理员提供）", value: @filter["token"], required: true)
              div(class: "form-grid") do
                text_field("latitude", "纬度", type: "number", step: "any", required: true, data: { check_in_target: "latitude" })
                text_field("longitude", "经度", type: "number", step: "any", required: true, data: { check_in_target: "longitude" })
              end
              button(type: "button", class: "tbtn", data: { action: "check-in#locate" }) { "获取当前位置" }
              p(class: "muted", data: { check_in_target: "status" }, role: "status")
              button(type: "submit", class: "tbtn pri") { "提交签到" }
            end
          end
          panel("照片时间轴 · 我的实操记录") do
            photos = @student.training_photos.where(course: @course).with_attached_image.order(id: :desc)
            div(class: "photo-grid") do
              photos.each do |photo|
                figure do
                  img(src: url_for(photo.image), alt: "课程实操照片", loading: "lazy") if photo.image.attached?
                  figcaption { photo.watermark_text.to_s }
                end
              end
            end
            empty("还没有实操照片") if photos.empty?
            Form(url: student_photos_path, method: :post, scope: false, multipart: true, class: "form-stack mt") do
              input(type: "hidden", name: "course_id", value: @course.id)
              text_field("image", "选择实操照片", type: "file", accept: "image/jpeg,image/png,image/webp", required: true)
              button(type: "submit", class: "tbtn pri") { "上传实操照片" }
            end
          end
          panel("语音与学习笔记") do
            @student.voice_notes.where(course: @course).with_attached_audio.order(id: :desc).each do |note|
              list_row(note.transcript.presence || "语音笔记", "#{date_label(note.created_at)} · #{note.status == 'pending' ? '音频已保存，待转写' : '已归档'}")
              audio(src: url_for(note.audio), controls: true, preload: "none") if note.audio.attached?
            end
            Form(url: student_voice_notes_path, method: :post, scope: false, multipart: true, class: "form-stack mt") do
              input(type: "hidden", name: "course_id", value: @course.id)
              label(class: "form-label") { span { "课程笔记" }; textarea(name: "transcript", class: "field", maxlength: 10000) }
              text_field("audio", "或上传语音", type: "file", accept: "audio/*")
              button(type: "submit", class: "tbtn pri") { "保存学习笔记" }
            end
          end
        end
      end
      aside(class: "stack") do
        panel("学情调查") do
          @course.surveys.active.each { |s| list_row(s.title) { action("进入问卷", student_survey_path(s)) } }
          empty("暂无课程问卷") if @course.surveys.active.empty?
        end
        panel("我的考勤") do
          records = @student.check_ins.where(course: @course).order(id: :desc)
          empty("暂无签到记录") if records.empty?
          records.each { |c| list_row(date_label(c.checked_in_at), c.gps_valid ? "位置验证通过" : "位置未通过验证，请联系管理员") }
        end
      end
    end
  end

  def policy_detail
    heading(@policy.title, [ @policy.document_number, @policy.issuing_authority ].compact.join(" · ")) { action("返回推荐清单", student_home_path) }
    panel("政策正文", subtitle: "有效期至 #{date_label(@policy.valid_until)}") do
      p(class: "rich-text") { @policy.content_text.presence || "政策正文待补充，请联系管理员。" }
      div(class: "actions mt") do
        @policy.tags.each { |tag| chip(tag.name) }
        chip(@interaction.status_label, "y")
      end
      div(class: "actions mt") do
        button_to(@interaction.saved? ? "取消收藏" : "收藏政策", student_policy_path(@policy, action_type: "save"), method: :patch, class: "tbtn")
        if @interaction.application_status == "none" && (@policy.valid_until.nil? || @policy.valid_until >= Date.current)
          button_to "登记已申报", student_policy_path(@policy, action_type: "apply"), method: :patch, class: "tbtn pri"
        end
      end
      p(class: "muted mt") { "申报登记用于跟踪办理进度。实际材料请按政策发布部门要求提交。" }
    end
  end

  def achievements
    heading("成果 · 价值验证", "让每一次学习、每一项政策与每一步成长都有据可查。") do
      action("导出成效报告", student_achievement_report_path, primary: true)
    end
    div(class: "hero-strip") do
      h2 { "我的成长档案" }
      p { "已完成 #{@record.metrics['已结业课程']} 门课程，#{@record.metrics['已获批政策']} 项政策登记获批，#{@record.metrics['已审核荣誉']} 项荣誉通过审核。" }
    end
    kpis(@record.metrics)
    div(class: "g2") do
      div(class: "stack") do
        panel("能力成长曲线", subtitle: "管理员录入的六维评估均分") do
          history = @record.assessments.to_a
          empty("暂无能力评估，记录评估后即可展示成长历史") if history.empty?
          render Components::Ui::GrowthChart.new(values: history.map { |a| [ date_label(a.assessed_on), a.average_score ] }) if history.any?
        end
        capabilities("能力明细 · 与同阶段均值对比", compare: true)
        panel("成果时间轴") do
          div(class: "timeline-list") { @record.archive.first(12).each { |r| list_row("#{r[:type]} · #{r[:title]}", "#{date_label(r[:date])} · #{r[:detail]}") } }
          empty if @record.archive.empty?
        end
        panel("产业动态追踪") do
          articles = KnowledgeArticle.published.order(id: :desc).limit(5)
          articles.each { |article| list_row(article.title, article.category) { action("阅读", student_knowledge_index_path(q: article.title)) } }
          empty("暂无产业知识条目") if articles.empty?
        end
      end
      div(class: "stack") do
        honors
        panel("成果构成") { bar_chart(@record.metrics) }
        panel("产品作品与案例展示墙") do
          cases = ShowcaseCase.published.includes(:student).with_attached_media.limit(8)
          cases.each do |c|
            list_row(c.title, "#{c.student.name} · 贡献分 #{c.contribution_score}")
            p(class: "rich-text muted") { c.body.to_s }
            if c.media.attached?
              if c.media.content_type.to_s.start_with?("video/")
                video(src: url_for(c.media), controls: true, preload: "metadata", class: "w-full")
              elsif c.media.content_type.to_s.start_with?("image/")
                img(src: url_for(c.media), alt: c.title, loading: "lazy", class: "w-full")
              end
            end
          end
          empty("暂无已发布案例") if cases.empty?
          Form(url: student_showcases_path, method: :post, scope: false, multipart: true, class: "form-stack mt") do
            text_field("showcase[title]", "作品标题", required: true, maxlength: 200)
            label(class: "form-label") { span { "作品介绍" }; textarea(name: "showcase[body]", class: "field", maxlength: 5000) }
            text_field("showcase[media]", "图片或短视频", type: "file", accept: "image/*,video/mp4,video/webm")
            button(type: "submit", class: "tbtn pri") { "上传我的作品" }
          end
          @student.showcase_cases.where(published: false).each { |c| list_row(c.title, "待审核展示") }
        end
        panel("下一步建议") do
          p(class: "why") { @record.completeness < 100 ? "完善主业、经营规模、收入和匹配标签，帮助系统为您提供更准确的推荐。" : "查看专属推荐并选择适合您的课程，完成培训后持续积累成长记录。" }
          div(class: "actions mt") { action("完善画像", student_me_path); action("查看课程", student_courses_path, primary: true) }
        end
      end
    end
  end

  def capabilities(title = "能力雷达 · 六维评估", compare: false)
    panel(title) do
      assessment = @record.latest_assessment
      if assessment
        render Components::Ui::Radar.new(scores: assessment.scores)
        values = CapabilityAssessment::DIMENSIONS.to_h { |key, label| [ label, assessment.scores[key] ] }
        bar_chart(values, max: 100)
        p(class: "muted mt") { "评估日期：#{date_label(assessment.assessed_on)} · 综合均分 #{assessment.average_score}" }
        if compare
          peers = CapabilityAssessment.where(student: ::Student.where(tips_stage: @student.tips_stage)).order(:assessed_on, :id).to_a.group_by(&:student_id).values.map(&:last)
          if peers.any?
            h3(class: "eyebrow mt") { "#{@student.tips_stage_label}学员均值（#{peers.size} 人）" }
            bar_chart(CapabilityAssessment::DIMENSIONS.to_h { |key, label| [ label, (peers.sum { |p| p.scores[key].to_f } / peers.size).round(1) ] }, max: 100)
          end
        end
      else
        empty("尚无六维能力评估记录")
      end
    end
  end

  def need_form
    panel("提交我的需求", subtitle: "技术、课程、政策或服务", id: "needs") do
      Form(url: student_needs_path, method: :post, scope: false, class: "form-stack") do
        label(class: "form-label") { span { "您当前最需要什么帮助？" }; textarea(name: "student_need[body]", class: "field", placeholder: "例如：希望学习农产品直播销售…", maxlength: 2000, required: true) }
        button(type: "submit", class: "tbtn pri") { "提交需求" }
      end
    end
  end

  def honors
    panel("我的荣誉室", subtitle: "提交后由所属管理员审核") do
      records = @student.honor_records.order(id: :desc)
      div(class: "g2") do
        records.each do |honor|
          div(class: "honor-tile") do
            div(class: "medal", aria_hidden: "true") { "✧" }
            strong { honor.title }
            p(class: "muted") { date_label(honor.awarded_on) }
            chip(honor.status_label, honor.status == "approved" ? "y" : "dim")
          end
        end
      end
      p(class: "muted") { "已有荣誉：#{@student.honors}" } if @student.honors.present?
      empty("还没有荣誉记录") if records.empty? && @student.honors.blank?
      Form(url: student_honors_path, method: :post, scope: false, multipart: true, class: "form-stack mt") do
        text_field("honor[title]", "荣誉名称", required: true, maxlength: 200)
        text_field("honor[awarded_on]", "获奖日期", type: "date")
        text_field("honor[evidence]", "证明材料（可选）", type: "file", accept: "image/*,application/pdf")
        button(type: "submit", class: "tbtn pri") { "提交新荣誉" }
      end
    end
  end

  def archive
    panel("我的学习档案", subtitle: "课程 / 笔记 / 照片 / 考试") do
      Form(url: student_courses_path, method: :get, scope: false, class: "filters") do
        input(name: "archive_q", value: @filter["archive_q"], class: "field", placeholder: "检索学习档案…", aria_label: "检索学习档案")
        button(type: "submit", class: "tbtn") { "检索" }
      end
      records = @record.archive(@filter["archive_q"].to_s)
      records.first(20).each { |r| list_row("#{r[:type]} · #{r[:title]}", "#{date_label(r[:date])} · #{r[:detail]}") { action("查看", r[:url]) if r[:url] } }
      empty("没有符合条件的学习档案") if records.empty?
    end
  end

  def calendar
    month = begin
      Date.strptime(@filter["month"].to_s, "%Y-%m").beginning_of_month
    rescue ArgumentError
      Date.current.beginning_of_month
    end
    items = @enrollments.values.select { |e| e.course.starts_at&.to_date&.between?(month, month.end_of_month) }.group_by { |e| e.course.starts_at.day }
    panel("日历课表", subtitle: month.strftime("%Y 年 %m 月")) do
      div(class: "actions", style: "margin-bottom:12px") do
        action("‹ 上月", student_courses_path(month: month.prev_month.strftime("%Y-%m")))
        action("本月", student_courses_path)
        action("下月 ›", student_courses_path(month: month.next_month.strftime("%Y-%m")))
      end
      div(class: "calendar-grid") do
        %w[一 二 三 四 五 六 日].each { |d| div(class: "muted") { d } }
        (month.cwday - 1).times { div }
        (1..month.end_of_month.day).each do |day|
          div(class: "calendar-day #{'has-course' if items[day]}") do
            plain day.to_s
            Array(items[day]).each { |e| a(href: student_course_path(e.course)) { small { e.course.title } } }
          end
        end
      end
    end
  end
end
