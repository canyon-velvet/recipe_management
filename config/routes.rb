Rails.application.routes.draw do
  # Authentication
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  get "register", to: "registrations#new"
  post "register", to: "registrations#create"

  # Recipes
  resources :recipes

  # Meal Plans
  resources :meal_plans

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  root "recipes#index"
end
