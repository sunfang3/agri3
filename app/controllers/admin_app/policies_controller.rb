# frozen_string_literal: true

module AdminApp
  class PoliciesController < AdminApp::BaseController
    def index
      render Views::AdminApp::Policies::Index.new(policies: Policy.order(created_at: :desc).includes(:tags))
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
      params.require(:policy).permit(:title, :content_text, :valid_until, :district_id, :published, :pdf_text, tag_ids: [])
    end
  end
end
