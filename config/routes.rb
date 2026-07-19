# frozen_string_literal: true

Rails.application.routes.draw do
  mount RailsIcons::Engine, at: "/rails_icons"
  mount ActionCable.server => "/cable"
  # Avo admin engine (resources land with product port units)
  mount_avo

  root "pages#home"

  get "up" => "rails/health#show", as: :rails_health_check
end
