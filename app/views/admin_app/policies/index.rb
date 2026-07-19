# frozen_string_literal: true

class Views::AdminApp::Policies::Index < Views::Base
  def initialize(policies: [])
    @policies = policies
  end

  def view_template
    div(class: "mx-auto max-w-3xl px-4 py-8 space-y-4") do
      div(class: "flex justify-between items-center") do
        h1(class: "text-xl font-bold") { "政策资源库" }
        a(href: new_admin_policy_path, class: "btn btn-primary btn-sm") { "新建" }
      end
      ul(class: "space-y-2") do
        @policies.each do |p|
          li(class: "card bg-base-100 shadow-sm") do
            div(class: "card-body p-4 gap-1") do
              div(class: "font-medium") { p.title }
              div(class: "text-xs opacity-70") do
                "valid_until=#{p.valid_until} · tags=#{p.tags.map(&:name).join(",")} · parse=#{p.parse_status}"
              end
              div(class: "flex gap-2") do
                button_to "PDF 解析", parse_pdf_admin_policy_path(p), method: :post, class: "btn btn-xs"
                if p.parse_status == "pending_review"
                  button_to "人工校对通过", approve_parse_admin_policy_path(p), method: :post, class: "btn btn-xs btn-success"
                end
              end
            end
          end
        end
      end
      a(href: admin_root_path, class: "btn btn-ghost") { "返回" }
    end
  end
end
