# frozen_string_literal: true

class Components::Ui::FlashBanner < Components::Base
  def initialize(notice: nil, alert: nil)
    @notice = notice
    @alert = alert
  end

  def view_template
    div(class: "alert alert-success text-sm") { @notice } if @notice.present?
    div(class: "alert alert-error text-sm") { @alert } if @alert.present?
  end
end
