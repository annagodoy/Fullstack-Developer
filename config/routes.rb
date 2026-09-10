Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  namespace :admin do
    root "dashboard#show"

    resources :users, except: :show
  end

  resource :profile, only: %i[show edit update destroy] do
    get :avatar
  end

  resource :registration, only: %i[new create]

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
