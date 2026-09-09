Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  namespace :admin do
    root "dashboard#show"
  end

  resource :profile, only: :show

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
