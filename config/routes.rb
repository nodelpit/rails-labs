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

  # Routes pour l'authentification
  namespace :auth do
    resource :registration, only: [ :new, :create, :edit, :update, :destroy ]
    resource :session, only: [ :new, :create, :destroy ]
    resource :password_reset, only: [ :new, :create, :edit, :update ]
    resource :password, only: [ :edit, :update ]
  end

  # Routes pour le chatbot
  namespace :chatbot do
    resources :conversations, except: [ :edit, :update ] do
      resources :messages, except: [ :edit, :update ]
    end
  end

  # Routes pour l'administration
  namespace :admin do
    root to: "dashboard#index"
    resources :users
  end

  # Routes pour l'API
  namespace :api do
    namespace :v2 do
      # Routes d'authentification
      post "auth/login", to: "auth#login"
      post "auth/refresh", to: "auth#refresh"

      # Routes de tâches (RESTful)
      resources :tasks
    end

    namespace :v1 do
      # Routes d'authentification API
      post "token", to: "tokens#create"
      delete "token", to: "tokens#destroy"

      # Routes de tâches (RESTful)
      resources :tasks
    end
  end
end
