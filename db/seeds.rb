# frozen_string_literal: true

# =============================================================================
# 齐鲁农创客 · 开发/演示 Seed
# 行政区划严格对齐济南市正式县级区划：10 区 + 2 县（不含功能区）
# =============================================================================

puts "==> 1/8 行政区划（济南市 10 区 + 2 县）"
count = District.seed_jinan!
puts "    active official districts: #{count} (expect #{District::JINAN_DISTRICTS.size})"

by_code = District.jinan_active.index_by(&:code)
District::JINAN_DISTRICTS.each do |meta|
  d = by_code.fetch(meta[:code])
  raise "区划名称不一致: #{meta[:code]} expected=#{meta[:name]} got=#{d.name}" unless d.name == meta[:name]
end

# 各区县地理中心（近似，用于签到演示）
COORDS = {
  "lixia"     => [ 36.666, 117.077 ],
  "shizhong"  => [ 36.651, 116.997 ],
  "huaiyin"   => [ 36.651, 116.901 ],
  "tianqiao"  => [ 36.678, 116.987 ],
  "licheng"   => [ 36.680, 117.065 ],
  "changqing" => [ 36.554, 116.752 ],
  "zhangqiu"  => [ 36.713, 117.526 ],
  "jiyang"    => [ 36.978, 117.210 ],
  "laiwu"     => [ 36.214, 117.675 ],
  "gangcheng" => [ 36.059, 117.811 ],
  "pingyin"   => [ 36.289, 116.456 ],
  "shanghe"   => [ 37.311, 117.157 ]
}.freeze

# 区县主导产业与示范学员画像（贴合本地农业特色）
DISTRICT_PROFILES = {
  "lixia"     => { industry: "都市农业", specialty: "设施园艺", scale: 25,  income: 180_000, honor: "都市农业示范园" },
  "shizhong"  => { industry: "休闲农业", specialty: "农旅融合", scale: 40,  income: 220_000, honor: "休闲农业点" },
  "huaiyin"   => { industry: "蔬菜",     specialty: "设施蔬菜", scale: 60,  income: 260_000, honor: "无公害蔬菜基地" },
  "tianqiao"  => { industry: "粮油",     specialty: "优质小麦", scale: 80,  income: 200_000, honor: nil },
  "licheng"   => { industry: "粮油",     specialty: "小麦玉米轮作", scale: 120, income: 550_000, honor: "示范家庭农场" },
  "changqing" => { industry: "生态农旅", specialty: "山地果品", scale: 90,  income: 320_000, honor: "生态农场" },
  "zhangqiu"  => { industry: "蔬菜",     specialty: "章丘大葱", scale: 150, income: 480_000, honor: "大葱地理标志种植户" },
  "jiyang"    => { industry: "蔬菜",     specialty: "黄瓜番茄", scale: 100, income: 360_000, honor: "蔬菜标准园" },
  "laiwu"     => { industry: "调味品原料", specialty: "生姜大蒜", scale: 80,  income: 410_000, honor: "生姜种植大户" },
  "gangcheng" => { industry: "林果",     specialty: "山地林果", scale: 70,  income: 240_000, honor: nil },
  "pingyin"   => { industry: "花卉",     specialty: "平阴玫瑰", scale: 55,  income: 380_000, honor: "玫瑰种植示范户" },
  "shanghe"   => { industry: "粮油",     specialty: "粮食高产", scale: 200, income: 420_000, honor: "种粮大户" }
}.freeze

ADMIN_NAMES = {
  "lixia" => "历下王科长", "shizhong" => "市中赵科长", "huaiyin" => "槐荫孙科长",
  "tianqiao" => "天桥周科长", "licheng" => "历城李科长", "changqing" => "长清吴科长",
  "zhangqiu" => "章丘郑科长", "jiyang" => "济阳冯科长", "laiwu" => "莱芜陈科长",
  "gangcheng" => "钢城褚科长", "pingyin" => "平阴卫科长", "shanghe" => "商河蒋科长"
}.freeze

puts "==> 2/8 标签库"
tags = {}
[
  [ :industry_grain,    "industry",            "粮油",       "grain" ],
  [ :industry_veg,      "industry",            "蔬菜",       "veg" ],
  [ :industry_flower,   "industry",            "花卉",       "flower" ],
  [ :industry_fruit,    "industry",            "林果",       "fruit" ],
  [ :industry_spice,    "industry",            "调味品原料", "spice" ],
  [ :industry_urban,    "industry",            "都市农业",   "urban" ],
  [ :industry_leisure,  "industry",            "休闲农业",   "leisure" ],
  [ :industry_eco,      "industry",            "生态农旅",   "eco" ],
  [ :object_farm,       "applicable_object",   "家庭农场",   nil ],
  [ :object_coop,       "applicable_object",   "农民合作社", nil ],
  [ :object_large,      "applicable_object",   "种养大户",   nil ],
  [ :scale_50,          "scale_threshold",     "规模≥50亩",  "50" ],
  [ :scale_100,         "scale_threshold",     "规模≥100亩", "100" ],
  [ :income_10w,        "income_threshold",    "年收入≥10万", "100000" ],
  [ :income_30w,        "income_threshold",    "年收入≥30万", "300000" ],
  [ :deadline_2027,     "deadline",            "2027截止",   "2027-12-31" ],
  [ :deadline_2028,     "deadline",            "2028截止",   "2028-12-31" ],
  [ :course_tech,       "course",              "种植技术",   nil ],
  [ :course_manage,     "course",              "经营管理",   nil ],
  [ :course_brand,      "course",              "品牌营销",   nil ]
].each do |key, category, name, value|
  tags[key] = Tag.find_or_create_by!(category: category, name: name) { |t| t.value = value }
end

# 产业名 → 标签
INDUSTRY_TAG = {
  "粮油" => tags[:industry_grain],
  "蔬菜" => tags[:industry_veg],
  "花卉" => tags[:industry_flower],
  "林果" => tags[:industry_fruit],
  "调味品原料" => tags[:industry_spice],
  "都市农业" => tags[:industry_urban],
  "休闲农业" => tags[:industry_leisure],
  "生态农旅" => tags[:industry_eco]
}.freeze

puts "==> 3/8 管理员（1 市级 + 每区县 1 名）"
Admin.find_or_create_by!(email: "city@jinan.local") do |a|
  a.name = "济南市农广校·市级管理员"
  a.password = "password"
  a.role = "city"
end

District::JINAN_CODES.each do |code|
  district = by_code.fetch(code)
  Admin.find_or_create_by!(email: "admin@#{code}.local") do |a|
    a.name = ADMIN_NAMES.fetch(code)
    a.password = "password"
    a.role = "district"
    a.district = district
  end
end

puts "==> 4/8 学员（每区县至少 2 名，共 #{District::JINAN_CODES.size * 2}+）"
student_index = 0
seeded_students = []

District::JINAN_CODES.each do |code|
  district = by_code.fetch(code)
  profile = DISTRICT_PROFILES.fetch(code)
  industry_tag = INDUSTRY_TAG.fetch(profile[:industry])

  2.times do |i|
    student_index += 1
    phone = format("138%08d", student_index) # 13800000001 …
    name = i.zero? ? "#{district.name.gsub(/[区县]/, '')}示范户#{student_index}" : "#{district.name.gsub(/[区县]/, '')}学员#{student_index}"

    scale = profile[:scale] * (i.zero? ? 1.0 : 0.55)
    income = profile[:income] * (i.zero? ? 1.0 : 0.6)

    student = Student.find_or_initialize_by(phone: phone)
    student.assign_attributes(
      name: name,
      district: district,
      primary_industry: profile[:industry],
      scale: scale.round(1),
      annual_income: income.round,
      honors: i.zero? ? profile[:honor] : nil,
      password: "password"
    )
    student.save!

    tag_list = [ industry_tag, tags[:object_farm] ]
    tag_list << tags[:scale_50] if scale >= 50
    tag_list << tags[:scale_100] if scale >= 100
    tag_list << tags[:income_10w] if income >= 100_000
    tag_list << tags[:income_30w] if income >= 300_000
    student.tags = tag_list.uniq
    seeded_students << student
  end
end

# 历城标杆学员固定姓名，便于手册演示
licheng_demo = Student.find_by!(phone: "13800000009") # 历城是第 5 个区 ×2 = 第 9、10 号
# Actually order: lixia 1-2, shizhong 3-4, huaiyin 5-6, tianqiao 7-8, licheng 9-10
if licheng_demo
  licheng_demo.update!(name: "张三", honors: "示范家庭农场")
end
shizhong_demo = Student.find_by(phone: "13800000003")
shizhong_demo&.update!(name: "李四")

puts "==> 5/8 政策资源（全市 + 特色区县）"
citywide = [
  {
    title: "济南市家庭农场示范补贴办法",
    content: "支持家庭农场扩大生产规模，对达标主体给予示范补贴与培训名额。适用粮油、蔬菜等主导产业。",
    tags: [ tags[:object_farm], tags[:scale_50], tags[:income_10w], tags[:deadline_2027] ],
    district: nil
  },
  {
    title: "新型农业经营主体贷款贴息政策",
    content: "对农民合作社、家庭农场生产经营贷款给予贴息支持，鼓励扩大再生产。",
    tags: [ tags[:object_farm], tags[:object_coop], tags[:income_10w], tags[:deadline_2028] ],
    district: nil
  },
  {
    title: "高素质农民培育工程实施方案",
    content: "组织农创客参加种植技术、经营管理与品牌营销培训，完成学时可获结业认定。",
    tags: [ tags[:course_tech], tags[:course_manage], tags[:deadline_2027] ],
    district: nil
  }
]

local_policies = [
  { code: "zhangqiu", title: "章丘大葱产业提升补贴", content: "支持章丘大葱标准化种植、冷链与品牌建设。", tag_keys: [ :industry_veg, :object_farm, :scale_50, :deadline_2027 ] },
  { code: "pingyin",  title: "平阴玫瑰特色产业扶持", content: "支持玫瑰种植、精深加工与文旅融合项目。", tag_keys: [ :industry_flower, :object_farm, :income_10w, :deadline_2028 ] },
  { code: "laiwu",    title: "莱芜生姜标准化基地奖励", content: "对生姜标准化种植基地与种苗繁育给予奖励。", tag_keys: [ :industry_spice, :scale_50, :object_large, :deadline_2027 ] },
  { code: "shanghe",  title: "商河粮食高产创建奖励", content: "对种粮大户高产攻关田给予测产奖励与农资补贴。", tag_keys: [ :industry_grain, :scale_100, :object_large, :deadline_2027 ] },
  { code: "licheng",  title: "历城农创客培育专项", content: "历城区农创客遴选、培训与跟踪服务专项资金。", tag_keys: [ :object_farm, :course_tech, :income_10w, :deadline_2027 ] },
  { code: "changqing", title: "长清生态农旅示范奖励", content: "支持山地果品与农旅融合示范点建设。", tag_keys: [ :industry_eco, :industry_fruit, :object_farm, :deadline_2028 ] }
]

citywide.each do |spec|
  p = Policy.find_or_create_by!(title: spec[:title]) do |pol|
    pol.content_text = spec[:content]
    pol.valid_until = Date.new(2027, 12, 31)
    pol.published = true
    pol.district = spec[:district]
    pol.parse_status = "approved"
  end
  p.update!(content_text: spec[:content], published: true) if p.content_text.blank?
  p.tags = spec[:tags]
end

local_policies.each do |spec|
  district = by_code.fetch(spec[:code])
  p = Policy.find_or_create_by!(title: spec[:title]) do |pol|
    pol.content_text = spec[:content]
    pol.valid_until = Date.new(2027, 12, 31)
    pol.published = true
    pol.district = district
    pol.parse_status = "manual"
  end
  p.update!(district: district, published: true)
  p.tags = spec[:tag_keys].map { |k| tags[k] }
end

puts "==> 6/8 师资与课程（覆盖主要区县）"
mentor_specs = [
  { name: "王守粮", code: "licheng",   specialty: "小麦高产栽培" },
  { name: "刘葱香", code: "zhangqiu",  specialty: "大葱标准化种植" },
  { name: "陈玫香", code: "pingyin",   specialty: "玫瑰栽培与加工" },
  { name: "张姜农", code: "laiwu",     specialty: "生姜病虫害防控" },
  { name: "赵粮仓", code: "shanghe",   specialty: "粮食烘干与仓储" },
  { name: "孙园丁", code: "jiyang",    specialty: "设施蔬菜" },
  { name: "周山果", code: "changqing", specialty: "山地果树" },
  { name: "吴市农", code: "lixia",     specialty: "都市农业运营" }
]

mentors = {}
mentor_specs.each do |spec|
  district = by_code.fetch(spec[:code])
  m = Mentor.find_or_create_by!(name: spec[:name]) do |mentor|
    mentor.specialty = spec[:specialty]
    mentor.district = district
    mentor.deep_tags = [ spec[:specialty] ]
    mentor.phone = format("139%08d", mentors.size + 1)
  end
  m.update!(district: district, specialty: spec[:specialty])
  mentors[spec[:code]] = m
end

course_specs = [
  { title: "小麦高产技术培训", code: "licheng", mentor: "licheng", place: "历城区农广校", tags: [ :course_tech, :industry_grain ], days: 7 },
  { title: "章丘大葱标准化种植班", code: "zhangqiu", mentor: "zhangqiu", place: "章丘区农业培训中心", tags: [ :course_tech, :industry_veg ], days: 14 },
  { title: "平阴玫瑰精深加工研修", code: "pingyin", mentor: "pingyin", place: "平阴县玫瑰产业园", tags: [ :course_brand, :industry_flower ], days: 21 },
  { title: "莱芜生姜绿色防控课堂", code: "laiwu", mentor: "laiwu", place: "莱芜区农广校", tags: [ :course_tech, :industry_spice ], days: 10 },
  { title: "商河种粮大户经营管理", code: "shanghe", mentor: "shanghe", place: "商河县农业农村局", tags: [ :course_manage, :industry_grain ], days: 28 },
  { title: "设施蔬菜水肥一体化", code: "jiyang", mentor: "jiyang", place: "济阳区蔬菜示范园", tags: [ :course_tech, :industry_veg ], days: 12 },
  { title: "农创客品牌营销实务", code: "lixia", mentor: "lixia", place: "市农广校（历下）", tags: [ :course_brand, :course_manage ], days: 5 },
  { title: "长清生态农旅运营实务", code: "changqing", mentor: "changqing", place: "长清区农广校", tags: [ :course_manage, :industry_eco ], days: 18 }
]

course_specs.each do |spec|
  district = by_code.fetch(spec[:code])
  mentor = mentors[spec[:mentor]]
  lat, lng = COORDS.fetch(spec[:code])
  course = Course.find_or_create_by!(title: spec[:title]) do |c|
    c.description = "#{district.name}·#{spec[:title]}"
    c.mentor = mentor
    c.mentor_name = mentor.name
    c.starts_at = spec[:days].days.from_now.change(hour: 9)
    c.ends_at = (spec[:days] + 1).days.from_now.change(hour: 17)
    c.place = spec[:place]
    c.latitude = lat
    c.longitude = lng
    c.district = district
    c.published = true
    c.deep_tags = spec[:tags].map(&:to_s)
  end
  course.update!(
    mentor: mentor,
    mentor_name: mentor.name,
    place: spec[:place],
    district: district,
    latitude: lat,
    longitude: lng,
    published: true
  )
  course.tags = spec[:tags].map { |k| tags[k] }
end

puts "==> 7/8 规则、知识库、案例、学情调查"
[
  { name: "起步期-小规模", stage: "T", conditions: { "max_scale" => 49 }, priority: 5 },
  { name: "成长期-中等规模", stage: "I", conditions: { "min_scale" => 50, "max_scale" => 99 }, priority: 10 },
  { name: "壮大期-规模与收入", stage: "P", conditions: { "min_scale" => 100, "min_income" => 200_000 }, priority: 15 },
  { name: "示范期-规模收入荣誉", stage: "S", conditions: { "min_scale" => 150, "min_income" => 400_000, "min_honors_present" => true }, priority: 20 }
].each do |spec|
  TipsStageRule.find_or_create_by!(name: spec[:name]) do |r|
    r.stage = spec[:stage]
    r.conditions = spec[:conditions]
    r.priority = spec[:priority]
    r.enabled = true
  end
end

[
  [ "小麦节水灌溉要点", "种植", "采用滴灌与测墒灌溉，降低亩均用水量，提高济南南部与沿黄粮油产区水分利用效率。" ],
  [ "章丘大葱移栽技术", "种植", "大葱育苗、移栽密度与培土管理，适配章丘黑土区气候与土壤条件。" ],
  [ "平阴玫瑰病虫害绿色防控", "种植", "玫瑰常见病虫害识别与生物防治，减少化学农药使用。" ],
  [ "家庭农场财务管理入门", "经营", "简易账本、成本核算与补贴项目档案管理，服务农创客主体。" ],
  [ "济南农产品区域公用品牌建设", "营销", "对接济南市公用品牌与电商渠道，提升本地特色产品溢价能力。" ]
].each do |title, category, body|
  KnowledgeArticle.find_or_create_by!(title: title) do |a|
    a.body = body
    a.category = category
    a.published = true
  end
end
# Reindex so Litesearch sees rows created/updated before the FTS table existed.
KnowledgeArticle.rebuild_search_index!

# 每区县 1 个已发布案例（用该区第一名学员）
District::JINAN_CODES.each_with_index do |code, idx|
  district = by_code.fetch(code)
  student = seeded_students[idx * 2]
  profile = DISTRICT_PROFILES.fetch(code)
  ShowcaseCase.find_or_create_by!(title: "#{district.name}·#{profile[:specialty]}典型案例") do |c|
    c.student = student
    c.district = district
    c.body = "#{student.name}扎根#{district.name}，从事#{profile[:industry]}（#{profile[:specialty]}），" \
             "通过政策匹配与培训提升经营能力。"
    c.contribution_score = 60 + (idx * 3)
    c.published = true
  end
end

licheng_course = Course.find_by!(title: "小麦高产技术培训")
%w[pre_training daily post_exam].each do |stype|
  titles = {
    "pre_training" => "训前需求调查（小麦班）",
    "daily" => "训中日评（小麦班）",
    "post_exam" => "训后考试（小麦班）"
  }
  Survey.find_or_create_by!(title: titles[stype]) do |s|
    s.survey_type = stype
    s.course = licheng_course
    s.active = true
    s.questions =
      if stype == "post_exam"
        [
          { "id" => "q1", "text" => "小麦拔节期水肥管理要点？", "correct" => "控旺促壮" },
          { "id" => "q2", "text" => "节水灌溉优先方式？", "correct" => "滴灌" }
        ]
      else
        [ { "id" => "need", "text" => stype == "daily" ? "今日收获" : "最希望学习的内容" } ]
      end
  end
end

# 历城示范报名一条 pending，便于后台 bulk confirm 演示
zhang = Student.find_by(phone: "13800000009")
if zhang && licheng_course
  Enrollment.find_or_create_by!(student: zhang, course: licheng_course) do |e|
    e.status = "pending"
  end
  AppMessage.find_or_create_by!(student: zhang, title: "欢迎使用农创客平台") do |m|
    m.body = "您的专属适配清单已生成，请到首页查看推荐政策与课程。"
    m.message_type = "system"
  end
end

puts "==> 8/8 动态阶段 + 全员规则匹配"
evaluator = Tips::StageEvaluator.new
Student.find_each { |s| evaluator.apply!(s) }
Matching::Runner.run_all!(engine: :rules)

puts ""
puts "========== Seed 完成 =========="
puts "区划: #{District.jinan_active.count}（正式 10 区 2 县）"
District::JINAN_DISTRICTS.each do |meta|
  d = by_code[meta[:code]]
  puts "  [#{meta[:kind]}] #{d.name} (#{d.code}) 学员=#{d.students.count} 管理员=#{d.admins.count}"
end
puts "学员=#{Student.count} 管理员=#{Admin.count} 政策=#{Policy.count} 课程=#{Course.count}"
puts "师资=#{Mentor.count} 标签=#{Tag.count} 匹配=#{ResourceMatch.count} 案例=#{ShowcaseCase.count}"
puts "登录示例: city@jinan.local / password ； admin@licheng.local / password"
puts "学员示例: 13800000009 / password （历城·张三）"
puts "================================"
