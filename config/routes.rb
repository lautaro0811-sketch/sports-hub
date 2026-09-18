Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root to: redirect("/login")

  get "login", to: "sessions#new", as: :login
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  namespace :admin do
    root to: "dashboard#index"
    resources :sports_complexes
    resources :pricing_schemes do
      member do
        post :assign_courts
      end
      resources :pricing_rules, only: %i[create edit update destroy]
    end
    resources :courts do
      resources :time_slots, only: %i[index create destroy] do
        collection do
          delete :destroy_all
          delete :destroy_day
        end
      end
    end
    resources :reservations, only: %i[index show update]
  end

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      post "auth/login", to: "authentication#login"

      resources :sports_complexes, only: %i[index show] do
        resources :courts, only: %i[index show]
      end

      resources :courts, only: %i[index show]

      resources :reservations, only: %i[index show create destroy]
    end
  end
end
