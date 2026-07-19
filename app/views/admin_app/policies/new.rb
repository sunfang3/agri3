# frozen_string_literal: true

class Views::AdminApp::Policies::New < Views::Base
  def initialize(policy:, tags: [])
    @policy = policy
    @tags = tags
  end

  def view_template
    div(class: "mx-auto max-w-lg px-4 py-8") do
      h1(class: "text-xl font-bold mb-4") { "新建政策" }
      render PolicyForm.new(model: @policy, url: admin_policies_path, method: :post, tags: @tags)
    end
  end
end
