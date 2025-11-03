Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :songs, only: [:index, :show]
      post 'scrapes', to: 'scrapes#create'
    end
  end
end
