Rails.application.routes.draw do
  root "site#index"

  devise_for :users
  
  resources :users do
    post :invite, on: :collection
  end
  resources :datalab, only: [:index] do
    collection do
      get :chat_history
      get :chat_history_details
      post :chat
    end
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

  # API
  namespace :api, defaults: {format: 'json'} do
    namespace :v2 do
      # Power BI views
      get  :view_fact_rates, to: "dw#view_fact_rates"
      get  :view_fact_targets_individual, to: "dw#view_fact_targets_individual"
      get  :view_fact_activities, to: "dw#view_fact_activities"
      get  :view_contracts, to: "dw#view_contracts"
      get  :view_dim_projects, to: "dw#view_dim_projects"
      get  :view_dim_companies, to: "dw#view_dim_companies"
      get  :view_dim_customers, to: "dw#view_dim_customers"
      get  :view_dim_users, to: "dw#view_dim_users"

      # Power BI dimension tables
      get  :dim_accounts, to: "dw#dim_accounts"
      get  :dim_companies, to: "dw#dim_companies"
      get  :dim_users, to: "dw#dim_users"
      get  :dim_customers, to: "dw#dim_customers"
      get  :dim_unbillables, to: "dw#dim_unbillables"
      get  :dim_projects, to: "dw#dim_projects"
      get  :dim_dates, to: "dw#dim_dates"
      get  :dim_roles, to: "dw#dim_roles"

      # Power BI fact tables
      get  :fact_rates, to: "dw#fact_rates"
      get  :fact_activities, to: "dw#fact_activities"
      get  :fact_invoices, to: "dw#fact_invoices"
      get  :fact_targets, to: "dw#fact_targets"
      get  :fact_projectusers, to: "dw#fact_projectusers"
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
