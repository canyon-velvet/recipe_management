Rails.application.routes.draw do
  # Authentication
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  get "register", to: "registrations#new"
  post "register", to: "registrations#create"

  # Recipes
  resources :recipes do
    get :search, on: :collection
  end

  # Ingredients & Sources (AJAX search + inline create)
  resources :ingredients, only: [:create] do
    get :search, on: :collection
  end
  resources :sources, only: [:create] do
    get :search, on: :collection
  end

  # Meal Plans
  resources :meal_plans, only: [:index, :show, :new, :create, :destroy] do
    resource :grocery_list, only: [:show]
  end

  # Grocery List Items (pantry toggle)
  resources :grocery_list_items, only: [:update]

  # Meal Slot Recipes (add/remove recipes from slots)
  resources :meal_slots, only: [] do
    resources :meal_slot_recipes, only: [:create]
  end
  resources :meal_slot_recipes, only: [:destroy, :update]

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  root "recipes#index"
end
