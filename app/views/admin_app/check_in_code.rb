class Views::AdminApp::CheckInCode < Views::WorkspaceBase
  def initialize(course:, token:)
    @course, @token = course, token
  end

  def view_template
    heading("课程签到码", @course.title) { action("返回课程", admin_course_path(@course)) }
    panel("现场签到", subtitle: "有效期 1 小时，仅已录取学员可签到") do
      p(class: "muted") { "向现场学员提供下方签到链接，或将签到码复制给学员在课程详情中提交。" }
      label(class: "form-label mt") do
        span { "签到码" }
        textarea(class: "field", readonly: true) { @token }
      end
      action("学员签到页面", student_course_path(@course, token: @token))
    end
  end
end
