# frozen_string_literal: true

Rails.application.routes.draw do
  mount RailsIcons::Engine, at: "/rails_icons"
  mount ActionCable.server => "/cable"
  mount_avo

  root "pages#home"

  get "up" => "rails/health#show", as: :rails_health_check

  # Public chat lobby (Litecable + Turbo Streams + phlex-reactive)
  get "chat", to: "chat#show", as: :chat
  patch "chat/identity", to: "chat_identities#update", as: :chat_identity

  scope path: "student", module: "student_app", as: "student" do
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"
    get "register", to: "registrations#new"
    post "register", to: "registrations#create"
    get "home", to: "home#show"
    resources :courses, only: [ :index, :show ]
    get "achievements", to: "workspace#achievements"
    get "achievements/report", to: "workspace#report", as: :achievement_report
    post "needs", to: "workspace#create_need", as: :needs
    post "honors", to: "workspace#create_honor", as: :honors
    post "showcases", to: "workspace#create_showcase", as: :showcases
    post "voice_notes", to: "workspace#create_voice_note", as: :voice_notes
    post "photos", to: "workspace#create_photo", as: :photos
    resources :policies, only: [ :show, :update ]
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
    get "students", to: "workspace#students"
    get "students/:id", to: "workspace#student", as: :student
    get "cockpit", to: "workspace#cockpit"
    get "resources", to: "workspace#resources"
    post "matching", to: "workspace#matching", as: :matching
    patch "needs/:id", to: "workspace#respond_need", as: :need
    patch "honors/:id", to: "workspace#review_honor", as: :honor
    patch "showcases/:id", to: "workspace#review_showcase", as: :showcase
    patch "mentor_answers/:id", to: "workspace#answer_question", as: :mentor_answer
    post "tags", to: "workspace#create_tag", as: :tags
    patch "tags/:id", to: "workspace#update_tag", as: :tag
    patch "policy_interactions/:id", to: "workspace#review_application", as: :policy_interaction
    post "students/:id/assessments", to: "workspace#assess", as: :student_assessments
    post "enrollments/bulk_confirm", to: "enrollments#bulk_confirm", as: :bulk_confirm_enrollments
    post "enrollments/bulk_ack", to: "enrollments#bulk_ack", as: :bulk_ack_enrollments
    resources :imports, only: [ :new, :create ]
    resources :policies, only: [ :index, :new, :create, :edit, :update ] do
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
