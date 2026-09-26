Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :songs, only: [:index, :show]
      post 'scrapes', to: 'scrapes#create'
      get 'charts/diff/latest', to: 'charts#diff_latest'
      get 'charts/history', to: 'charts#history'
      delete 'charts/:chart_date', to: 'charts#destroy'
      get 'environment', to: 'environment#show'
      resource :settings, only: [:show, :update]
      resources :update_runs, only: [:index, :create, :show, :destroy] do
        member do
          post :verify
        end
        resources :items, only: [:update], controller: 'update_items'
      end
    end
  end
end
