Rails.application.routes.draw do
  # API routes
  namespace :api do
    namespace :v1 do
      resources :products
      resources :categories, only: [ :index ]

      resource :cart, only: [ :show ] do
        resources :items, only: [ :create, :update, :destroy ], controller: "cart_items"
      end

      resources :orders, only: [ :index, :show, :create ] do
        member do
          patch :cancel
          patch :status, action: :update_status
        end
      end
    end
  end

  # Web routes (keeping existing for now)
  resources :products
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "products#index"
end
