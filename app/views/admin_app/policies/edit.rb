class Views::AdminApp::Policies::Edit < Views::WorkspaceBase
  def initialize(policy:, tags: [])
    @policy, @tags = policy, tags
  end

  def view_template
    heading("编辑政策 · 人工校对", @policy.title) { action("返回资源库", admin_resources_path) }
    panel("政策信息") do
      p(class: "note") { @policy.errors.full_messages.join("；") } if @policy.errors.any?
      if @policy.parse_status == "pending_review"
        panel("解析建议 · 请核对原文") do
          (@policy.parsed_fields || {}).each { |key, value| list_row(key, Array(value).join("、")) }
        end
      end
      render PolicyForm.new(model: @policy, url: admin_policy_path(@policy), method: :patch, tags: @tags)
      button_to "确认校对通过", approve_parse_admin_policy_path(@policy), method: :post, class: "tbtn pri mt" if @policy.parse_status == "pending_review"
    end
  end
end
