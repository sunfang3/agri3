# frozen_string_literal: true

module AdminApp
  class PoliciesController < AdminApp::BaseController
    def index
      redirect_to admin_resources_path
    end

    def edit
      render Views::AdminApp::Policies::Edit.new(policy: Policy.find(params[:id]), tags: Tag.order(:category, :name))
    end

    def update
      policy = Policy.find(params[:id])
      if policy.update(policy_params)
        policy.update!(parse_status: "approved") if params[:approve_parse] == "1"
        redirect_to admin_resources_path, notice: "政策已保存"
      else
        render Views::AdminApp::Policies::Edit.new(policy: policy, tags: Tag.order(:category, :name)), status: :unprocessable_entity
      end
    end

    def new
      render Views::AdminApp::Policies::New.new(policy: Policy.new, tags: Tag.order(:category, :name))
    end

    def create
      policy = Policy.new(policy_params)
      if policy.save
        tag_ids = Array(params.dig(:policy, :tag_ids) || params[:tag_ids]).map(&:to_i).reject(&:zero?)
        policy.tag_ids = tag_ids if tag_ids.any?
        track_admin_action!("policy_create", { id: policy.id })
        redirect_to admin_policies_path, notice: "政策已创建"
      else
        render Views::AdminApp::Policies::New.new(policy:, tags: Tag.order(:category, :name)), status: :unprocessable_entity
      end
    end

    def parse_pdf
      policy = Policy.find(params[:id])
      if policy.pdf_text.blank? && policy.content_text.blank?
        return redirect_to edit_admin_policy_path(policy), alert: "请先补充政策原文，再提取字段"
      end
      policy.update!(pdf_text: policy.content_text) if policy.pdf_text.blank?
      Policies::PdfParser.new.parse(policy)
      track_admin_action!("policy_parse", { id: policy.id })
      redirect_to admin_policies_path, notice: "PDF 已解析，待人工校对"
    end

    def approve_parse
      policy = Policy.find(params[:id])
      Policies::PdfParser.new.approve!(policy, overrides: params.permit(:title, :content_text, :valid_until).to_h.symbolize_keys)
      redirect_to admin_policies_path, notice: "校对已通过"
    end

    private

    def policy_params
      params.require(:policy).permit(:title, :document_number, :issuing_authority, :content_text, :valid_until, :district_id, :published, :pdf_text, tag_ids: [])
    end
  end
end
