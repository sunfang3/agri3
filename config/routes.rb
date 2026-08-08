# frozen_string_literal: true

Rails.application.routes.draw do
  mount RailsIcons::Engine, at: "/rails_icons"
  mount ActionCable.server => "/cable"
  mount_avo

  root "pages#home"

  get "up" => "rails/health#show", as: :rails_health_check

  scope path: "student", module: "student_app", as: "student" do
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"
    get "register", to: "registrations#new"
    post "register", to: "registrations#create"
    get "home", to: "home#show"
    get "me", to: "profiles#show"
    patch "me", to: "profiles#update"
    resources :enrollments, only: [ :create ]
    resources :messages, only: [ :index ]
    resources :check_ins, only: [ :create ]
    resources :knowledge, only: [ :index ]
    resources :mentor_answers, only: [ :create ]
    resources :surveys, only: [ :index, :show ] do
      member do
        post :respond
      end
    end
  end

  scope path: "admin", module: "admin_app", as: "admin" do
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"
    root to: "dashboard#show"
    post "enrollments/bulk_confirm", to: "enrollments#bulk_confirm", as: :bulk_confirm_enrollments
    post "enrollments/bulk_ack", to: "enrollments#bulk_ack", as: :bulk_ack_enrollments
    resources :imports, only: [ :new, :create ]
    resources :policies, only: [ :index, :new, :create ] do
      member do
        post :parse_pdf
        post :approve_parse
      end
    end
    resources :courses, only: %i[index show new create edit update] do
      resources :enrollments, only: %i[create update destroy], controller: "course_enrollments"
    end
    resources :surveys, only: [ :index, :new, :create ]
    get "export/students", to: "exports#students", as: :export_students
  end
end
