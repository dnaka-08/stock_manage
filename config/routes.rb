Rails.application.routes.draw do
  root to: 'tops#index'
  
  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'
  
  get 'signup', to: 'users#new'
  resources :users, only: [:index, :new, :create, :edit, :update, :destroy]
  resources :stores, only: [:index, :new, :create, :edit, :update, :destroy]
  resources :products, only: [:index, :new, :create, :edit, :update, :destroy]
  resources :stocks, only: [:index]
  resources :stock_details, only: [:index, :new, :create, :destroy]
  resources :mng_tables, only:[:index]
  resources :output_mng_talbles, only:[:index]
  resources :distributes, only:[:new, :create]
end
