require "test_helper"

class WorkspaceMigrationTest < ActionDispatch::IntegrationTest
  setup do
    @district = District.create!(name: "迁移测试区", code: "ui-#{SecureRandom.hex(4)}")
    @other_district = District.create!(name: "隔离测试区", code: "ui-other-#{SecureRandom.hex(4)}")
    @student = Student.create!(name: "界面学员", phone: "139#{rand(10_000_000..99_999_999)}", district: @district, password: "password")
    @other = Student.create!(name: "其他区学员", phone: "139#{rand(10_000_000..99_999_999)}", district: @other_district, password: "password")
    @admin = Admin.create!(name: "界面管理员", email: "ui-#{SecureRandom.hex(4)}@test.local", role: "district", district: @district, password: "password")
    @course = Course.create!(title: "实操课程", district: @district, capacity: 10, published: true, starts_at: 1.day.from_now)
    @policy = Policy.create!(title: "真实政策", published: true, valid_until: 1.year.from_now, document_number: "农〔2026〕1号")
  end

  test "all prototype destinations render actual records and navigation" do
    login_student
    [ student_home_path, student_me_path, student_courses_path, student_achievements_path, student_course_path(@course), student_policy_path(@policy) ].each do |path|
      get path
      assert_response :success, path
      assert_select "nav[aria-label='主导航'] a[href='#{student_courses_path}']"
      assert_no_match(/2,884|张长河|73\.8/, response.body)
    end
    login_admin
    [ admin_root_path, admin_students_path, admin_student_path(@student), admin_cockpit_path, admin_resources_path, edit_admin_policy_path(@policy) ].each do |path|
      get path
      assert_response :success, path
      assert_select "a[href='#{admin_students_path}']"
    end
  end

  test "student need and honor pass through scoped admin review to the student record" do
    login_student
    post student_needs_path, params: { student_need: { body: "需要电商课程", status: "responded" } }
    need = @student.student_needs.last
    assert_equal "pending", need.status
    post student_honors_path, params: { honor: { title: "示范家庭农场", status: "approved" } }
    honor = @student.honor_records.last
    assert_equal "pending", honor.status
    login_admin
    patch admin_need_path(need), params: { student_need: { status: "responded", response: "已安排专题课程" } }
    assert_equal "responded", need.reload.status
    assert @student.app_messages.exists?(body: "已安排专题课程")
    patch admin_honor_path(honor), params: { status: "approved" }
    assert_equal "approved", honor.reload.status
    get student_achievements_path
    assert_response :success
    assert_match "示范家庭农场", response.body
  end

  test "policy detail collection application and approval form a real conversion path" do
    login_student
    get student_policy_path(@policy)
    interaction = @student.policy_interactions.find_by!(policy: @policy)
    assert interaction.viewed_at.present?
    patch student_policy_path(@policy), params: { action_type: "save" }
    assert interaction.reload.saved?
    patch student_policy_path(@policy), params: { action_type: "apply", application_status: "approved" }
    assert_equal "applied", interaction.reload.application_status
    login_admin
    patch admin_policy_interaction_path(interaction), params: { status: "approved" }
    assert_equal "approved", interaction.reload.application_status
    get student_achievement_report_path
    assert_response :success
    assert_includes response.body, @student.name
  end

  test "new admin workflows cannot access another district student" do
    need = @other.student_needs.create!(body: "隔离需求")
    honor = @other.honor_records.create!(title: "隔离荣誉")
    interaction = @other.policy_interactions.create!(policy: @policy, application_status: "applied")
    login_admin
    get admin_student_path(@other)
    assert_response :not_found
    patch admin_need_path(need), params: { student_need: { response: "越权", status: "responded" } }
    assert_response :not_found
    patch admin_honor_path(honor), params: { status: "approved" }
    assert_response :not_found
    patch admin_policy_interaction_path(interaction), params: { status: "approved" }
    assert_response :not_found
    post admin_student_assessments_path(@other), params: { assessment: { assessed_on: Date.current, scores: scores } }
    assert_response :not_found
    get admin_students_path(q: @other.name)
    assert_no_match @other.phone, response.body
  end

  test "assessments validate actual scores and appear in the growth view" do
    login_admin
    assert_difference -> { @student.capability_assessments.count }, 1 do
      post admin_student_assessments_path(@student), params: { assessment: { assessed_on: Date.current, scores: scores } }
    end
    assert_no_difference -> { @student.capability_assessments.count } do
      post admin_student_assessments_path(@student), params: { assessment: { assessed_on: Date.current, scores: scores.merge("technology" => "invalid") } }
    end
    login_student
    get student_achievements_path
    assert_response :success
    assert_includes response.body, "综合均分 80.0"
  end

  test "course notes require admission and persist text without fake ASR" do
    login_student
    post student_voice_notes_path, params: { course_id: @course.id, transcript: "课程要点" }
    assert_response :not_found
    Enrollment.create!(student: @student, course: @course, status: "enrolled")
    post student_voice_notes_path, params: { course_id: @course.id, transcript: "课程要点" }
    assert_redirected_to student_course_path(@course)
    assert_equal "课程要点", @student.voice_notes.last.transcript
    get student_course_path(@course)
    assert_response :success
    assert_includes response.body, "课程要点"
  end

  test "course and archive searches use independent query parameters" do
    Enrollment.create!(student: @student, course: @course, status: "completed")
    login_student
    get student_courses_path(q: "不存在")
    assert_match "没有符合条件的课程", response.body
    get student_courses_path(archive_q: "实操")
    assert_includes response.body, "实操课程"
    get student_courses_path(archive_q: "不存在")
    assert_includes response.body, "没有符合条件的学习档案"
  end

  test "honor evidence photo and showcase uploads survive rendering and scoped review" do
    login_student
    Enrollment.create!(student: @student, course: @course, status: "enrolled")
    file = Tempfile.new([ "ui-evidence", ".png" ])
    file.binmode
    file.write(Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aKwAAAABJRU5ErkJggg=="))
    file.flush
    upload = -> { Rack::Test::UploadedFile.new(file.path, "image/png") }
    post student_photos_path, params: { course_id: @course.id, image: upload.call }
    assert @student.training_photos.last.image.attached?
    get student_course_path(@course)
    assert_response :success
    assert_select "figure img[alt='课程实操照片']"
    post student_honors_path, params: { honor: { title: "有材料的荣誉", evidence: upload.call } }
    assert @student.honor_records.last.evidence.attached?
    post student_showcases_path, params: { showcase: { title: "我的农产品", body: "种植实践", media: upload.call, published: true } }
    showcase = @student.showcase_cases.last
    assert showcase.media.attached?
    refute showcase.published?
    login_admin
    get admin_student_path(@student)
    assert_response :success
    patch admin_showcase_path(showcase), params: { published: "1" }
    assert showcase.reload.published?
    get student_achievements_path
    assert_response :success
    assert_includes response.body, "我的农产品"
  ensure
    file&.close!
  end

  test "signed check in codes are restricted to course owners and admitted students" do
    login_admin
    get check_in_code_admin_course_path(@course)
    assert_response :success
    other_course = Course.create!(title: "外区课程", district: @other_district)
    get check_in_code_admin_course_path(other_course)
    assert_response :not_found
    token = CheckIns::QrService.new.generate_token(@course)
    assert_raises(ArgumentError) do
      CheckIns::QrService.new.check_in!(student: @student, course: @course, token: token + "tampered", latitude: 36, longitude: 117)
    end
    Enrollment.create!(student: @student, course: @course, status: "enrolled")
    login_student
    post student_check_ins_path, params: { course_id: @course.id, token: token, latitude: 36, longitude: 117 }
    assert_redirected_to student_course_path(@course)
    assert @student.check_ins.exists?(course: @course)
  end

  test "capacity is enforced at both student registration and admission" do
    @course.update!(capacity: 1)
    Enrollment.create!(student: @other, course: @course, status: "enrolled")
    login_student
    assert_no_difference -> { Enrollment.count } do
      post student_enrollments_path, params: { course_id: @course.id }
    end
    enrollment = Enrollment.create!(student: @student, course: @course, status: "pending")
    assert_raises(ArgumentError) { enrollment.confirm! }
    assert_equal "pending", enrollment.reload.status
  end

  test "shared tag changes require a city or system administrator" do
    login_admin
    post admin_tags_path, params: { tag: { name: "受控标签", category: "industry" } }
    assert_response :forbidden
    city = Admin.create!(name: "市管理员", email: "city-ui-#{SecureRandom.hex(4)}@test.local", role: "city", password: "password")
    post admin_login_path, params: { email: city.email, password: "password" }
    post admin_tags_path, params: { tag: { name: "受控标签", category: "industry" } }
    assert Tag.exists?(name: "受控标签", category: "industry")
  end

  private

  def scores = CapabilityAssessment::DIMENSIONS.keys.to_h { |key| [ key, "80" ] }
  def login_student
    post student_login_path, params: { phone: @student.phone, password: "password" }
  end
  def login_admin
    post admin_login_path, params: { email: @admin.email, password: "password" }
  end
end
