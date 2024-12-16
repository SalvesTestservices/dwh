Rails.application.routes.draw do
  root "site#index"

  devise_for :users
  
  resources :users do
    post :invite, on: :collection
  end
  resources :data_targets, only: [:index] do
    get :quarter_targets, on: :collection
  end

  # DWH
  namespace :dwh do
    resources :dp_pipelines do
      member do
        patch :move
      end
    end
    resources :dp_tasks, except: [:index, :show] do
      post :pause
      post :start
      member do
        patch :move
      end
    end
    resources :dp_runs, only: [:show, :create, :destroy] do
      get :quality_checks
    end
  end

  # Datalab
  namespace :datalab do
    resources :reports do
      member do
        post :duplicate
        post :generate
        get :export
      end
    end
    
    resources :designer, only: [:show, :update] do
      member do
        post :preview
      end
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  mount GoodJob::Engine => '/jobs', as: 'jobs'
end
