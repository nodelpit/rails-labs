Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  namespace :auth do
    resource :registration
    resource :session
    resource :password_reset
    resource :password
  end

  namespace :chatbot do
    resources :conversations do
      resources :messages
    end
  end

  namespace :admin do
    root to: "dashboard#index"
    resources :users
  end

  namespace :api do
    namespace :v1 do
      resources :tasks
    end
  end
end
