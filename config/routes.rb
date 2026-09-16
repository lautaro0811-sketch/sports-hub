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
      resources :time_slots, only: %i[index create destroy]
    end
    resources :reservations, only: %i[index show update]
  end

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      post "auth/login", to: "authentication#login"

      resources :sports_complexes, only: %i[index show] do
        resources :courts, only: %i[index show]
      end

      resources :reservations, only: %i[index show create]
    end
  end
end
