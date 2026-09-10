Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root to: redirect("/login")

  get "login", to: "sessions#new", as: :login
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  namespace :admin do
    root to: "sports_complexes#index"
    resources :sports_complexes
    resources :courts do
      resources :time_slots, only: [ :index, :create, :destroy ]
    end
    resources :reservations, only: [ :index, :show, :update ]
  end

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :sports_complexes, only: [ :index, :show ]
      resources :courts, only: [ :index, :show ]
      resources :reservations, only: [ :index, :show, :create ]
    end
  end
end
