module StudentApp
  class PoliciesController < ApplicationController
    include StudentAuthenticatable
    before_action :require_student!
    before_action :set_policy

    def show
      interaction = current_student.policy_interactions.find_or_initialize_by(policy: @policy)
      interaction.update!(viewed_at: interaction.viewed_at || Time.current)
      render Views::StudentApp::Workspace.new(student: current_student, page: :policy, policy: @policy, interaction: interaction)
    end

    def update
      interaction = current_student.policy_interactions.find_or_initialize_by(policy: @policy)
      if params[:action_type] == "save"
        interaction.saved = !interaction.saved
      elsif params[:action_type] == "apply" && interaction.application_status == "none" && (@policy.valid_until.nil? || @policy.valid_until >= Date.current)
        interaction.application_status = "applied"
      end
      interaction.save!
      redirect_to student_policy_path(@policy), notice: "政策进度已更新"
    end

    private

    def set_policy
      @policy = Policy.published.find(params[:id])
    end
  end
end
