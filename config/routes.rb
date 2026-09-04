Rails.application.routes.draw do
  # Autenticación de sesiones para el Back-office
  get  "login",  to: "sessions#new",     as: :login
  post "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  # Espacio de nombres para el Back-Office
  namespace :admin do
    root to: "sports_complexes#index"
    resources :sports_complexes
    resources :courts
    resources :reservations, only: [:index, :show, :update]
  end

  # Redirección de la raíz del sitio al login o panel
  root to: redirect("/login")
end