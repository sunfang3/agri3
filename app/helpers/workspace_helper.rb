module WorkspaceHelper
  def workspace_admin
    @workspace_admin ||= Admin.find_by(id: session[:admin_id]) if session[:admin_id]
  end

  def workspace_student
    @workspace_student ||= Student.find_by(id: session[:student_id]) if session[:student_id]
  end

  def workspace_navigation
    if request.path.start_with?("/admin") && controller_name != "sessions"
      [ [ "全市 / 区县概览", admin_root_path, "◈" ], [ "精准匹配驾驶舱", admin_cockpit_path, "◎" ],
        [ "学员档案 · 审核录取", admin_students_path, "▤" ], [ "政策资源 · 标签", admin_resources_path, "◇" ],
        [ "课程与班级", admin_courses_path, "▣" ], [ "学情调查", admin_surveys_path, "▥" ],
        [ "Excel 导入", new_admin_import_path, "↥" ] ]
    else
      [ [ "首页 · 专属适配", student_home_path, "◈" ], [ "课程 · 报名", student_courses_path, "▣" ],
        [ "成果 · 成长档案", student_achievements_path, "◇" ], [ "我的 · 全息画像", student_me_path, "◎" ],
        [ "消息通知", student_messages_path, "✉" ], [ "农技知识库", student_knowledge_index_path, "▤" ],
        [ "学情调查", student_surveys_path, "▥" ] ]
    end
  end

  def workspace_title
    workspace_navigation.find { |_, path, _| request.path == path }&.first || "齐鲁农创客 · 培育服务平台"
  end

  def workspace_active?(path)
    return request.path == path if path == admin_root_path

    request.path == path || request.path.start_with?("#{path}/") ||
      (path == admin_resources_path && request.path.start_with?("/admin/policies"))
  end

  def workspace_portal?
    request.path == "/" || controller_name.in?(%w[sessions registrations])
  end
end
