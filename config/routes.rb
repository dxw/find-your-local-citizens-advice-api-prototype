Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resources :offices, only: [:show]
  resources :internal_postgres_search, only: [:show]
  resources :external_postgres_search, only: [:show]
  resources :dynamo_search, only: [:show]
  # Defines the root path route ("/")
  # root "articles#index"
end
