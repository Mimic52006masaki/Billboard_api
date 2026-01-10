Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :songs, only: [:index, :show]
      post 'scrapes', to: 'scrapes#create'
      get 'charts/diff/latest', to: 'charts#diff_latest'
      get 'charts/history', to: 'charts#history'
      delete 'charts/:chart_date', to: 'charts#destroy'
    end
  end
end
