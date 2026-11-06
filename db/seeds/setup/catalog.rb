# frozen_string_literal: true

COORDINATES = {
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

TAG_SPECS = [
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
].freeze

CITY_POLICY_SPECS = [
  {
    title: "济南市家庭农场示范补贴办法",
    content: "支持家庭农场扩大生产规模，对达标主体给予示范补贴与培训名额。适用粮油、蔬菜等主导产业。",
    tags: [ :object_farm, :scale_50, :income_10w, :deadline_2027 ],
    district: nil
  },
  {
    title: "新型农业经营主体贷款贴息政策",
    content: "对农民合作社、家庭农场生产经营贷款给予贴息支持，鼓励扩大再生产。",
    tags: [ :object_farm, :object_coop, :income_10w, :deadline_2028 ],
    district: nil
  },
  {
    title: "高素质农民培育工程实施方案",
    content: "组织农创客参加种植技术、经营管理与品牌营销培训，完成学时可获结业认定。",
    tags: [ :course_tech, :course_manage, :deadline_2027 ],
    district: nil
  }
].freeze

LOCAL_POLICY_SPECS = [
  { code: "zhangqiu", title: "章丘大葱产业提升补贴", content: "支持章丘大葱标准化种植、冷链与品牌建设。", tag_keys: [ :industry_veg, :object_farm, :scale_50, :deadline_2027 ] },
  { code: "pingyin",  title: "平阴玫瑰特色产业扶持", content: "支持玫瑰种植、精深加工与文旅融合项目。", tag_keys: [ :industry_flower, :object_farm, :income_10w, :deadline_2028 ] },
  { code: "laiwu",    title: "莱芜生姜标准化基地奖励", content: "对生姜标准化种植基地与种苗繁育给予奖励。", tag_keys: [ :industry_spice, :scale_50, :object_large, :deadline_2027 ] },
  { code: "shanghe",  title: "商河粮食高产创建奖励", content: "对种粮大户高产攻关田给予测产奖励与农资补贴。", tag_keys: [ :industry_grain, :scale_100, :object_large, :deadline_2027 ] },
  { code: "licheng",  title: "历城农创客培育专项", content: "历城区农创客遴选、培训与跟踪服务专项资金。", tag_keys: [ :object_farm, :course_tech, :income_10w, :deadline_2027 ] },
  { code: "changqing", title: "长清生态农旅示范奖励", content: "支持山地果品与农旅融合示范点建设。", tag_keys: [ :industry_eco, :industry_fruit, :object_farm, :deadline_2028 ] }
].freeze

MENTOR_SPECS = [
  { name: "王守粮", code: "licheng",   specialty: "小麦高产栽培" },
  { name: "刘葱香", code: "zhangqiu",  specialty: "大葱标准化种植" },
  { name: "陈玫香", code: "pingyin",   specialty: "玫瑰栽培与加工" },
  { name: "张姜农", code: "laiwu",     specialty: "生姜病虫害防控" },
  { name: "赵粮仓", code: "shanghe",   specialty: "粮食烘干与仓储" },
  { name: "孙园丁", code: "jiyang",    specialty: "设施蔬菜" },
  { name: "周山果", code: "changqing", specialty: "山地果树" },
  { name: "吴市农", code: "lixia",     specialty: "都市农业运营" }
].freeze

COURSE_SPECS = [
  # —— 市直班（district 空）——
  {
    kind: :city_direct, title: "市直·高素质农民培育示范班",
    place: "市农广校（市直）", mentor: :city, tags: [ :course_tech, :course_manage, :object_farm ], days: 10,
    description: "济南市农广校市直班。各区学员可报；市级录取；户籍区知会/备案。"
  },
  {
    kind: :city_direct, title: "市直·农创客品牌营销实务",
    place: "市农广校（市直）", mentor: :city, tags: [ :course_brand, :course_manage ], days: 5,
    description: "市直品牌营销班。市级录取；区县仅对辖区学员备案。"
  },
  {
    kind: :city_direct, title: "市直·政策解读与申报辅导",
    place: "市农广校（市直）", mentor: :city, tags: [ :course_manage, :object_farm ], days: 3,
    description: "惠农政策与申报辅导市直班。"
  },
  # —— 区办班（district 指向开班区）——
  { kind: :district, title: "小麦高产技术培训", code: "licheng", mentor: "licheng", place: "历城区农广校", tags: [ :course_tech, :industry_grain ], days: 7 },
  { kind: :district, title: "章丘大葱标准化种植班", code: "zhangqiu", mentor: "zhangqiu", place: "章丘区农业培训中心", tags: [ :course_tech, :industry_veg ], days: 14 },
  { kind: :district, title: "平阴玫瑰精深加工研修", code: "pingyin", mentor: "pingyin", place: "平阴县玫瑰产业园", tags: [ :course_brand, :industry_flower ], days: 21 },
  { kind: :district, title: "莱芜生姜绿色防控课堂", code: "laiwu", mentor: "laiwu", place: "莱芜区农广校", tags: [ :course_tech, :industry_spice ], days: 10 },
  { kind: :district, title: "商河种粮大户经营管理", code: "shanghe", mentor: "shanghe", place: "商河县农业农村局", tags: [ :course_manage, :industry_grain ], days: 28 },
  { kind: :district, title: "设施蔬菜水肥一体化", code: "jiyang", mentor: "jiyang", place: "济阳区蔬菜示范园", tags: [ :course_tech, :industry_veg ], days: 12 },
  { kind: :district, title: "长清生态农旅运营实务", code: "changqing", mentor: "changqing", place: "长清区农广校", tags: [ :course_manage, :industry_eco ], days: 18 },
  { kind: :district, title: "历下都市农业运营入门", code: "lixia", mentor: "lixia", place: "历下区农广校", tags: [ :course_manage, :industry_urban ], days: 6 }
].freeze

RULE_SPECS = [
  { name: "起步期-小规模", stage: "T", conditions: { "max_scale" => 49 }, priority: 5 },
  { name: "成长期-中等规模", stage: "I", conditions: { "min_scale" => 50, "max_scale" => 99 }, priority: 10 },
  { name: "壮大期-规模与收入", stage: "P", conditions: { "min_scale" => 100, "min_income" => 200_000 }, priority: 15 },
  { name: "示范期-规模收入荣誉", stage: "S", conditions: { "min_scale" => 150, "min_income" => 400_000, "min_honors_present" => true }, priority: 20 }
].freeze

ARTICLE_SPECS = [
  [ "小麦节水灌溉要点", "种植", "采用滴灌与测墒灌溉，降低亩均用水量，提高济南南部与沿黄粮油产区水分利用效率。" ],
  [ "章丘大葱移栽技术", "种植", "大葱育苗、移栽密度与培土管理，适配章丘黑土区气候与土壤条件。" ],
  [ "平阴玫瑰病虫害绿色防控", "种植", "玫瑰常见病虫害识别与生物防治，减少化学农药使用。" ],
  [ "家庭农场财务管理入门", "经营", "简易账本、成本核算与补贴项目档案管理，服务农创客主体。" ],
  [ "济南农产品区域公用品牌建设", "营销", "对接济南市公用品牌与电商渠道，提升本地特色产品溢价能力。" ]
].freeze
