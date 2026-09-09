Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  namespace :admin do
    root "dashboard#show"
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
