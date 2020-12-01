Rails.application.routes.draw do
  root to: 'tops#index'
  
  #get 'login', to: 'sessions#new'
  #post 'login', to: 'sessions#create'
  #delete 'logout', to: 'sessions#destroy'
  
  get 'signup', to: 'users#new'
  
  get 'home/index'
  # Add route for OmniAuth callback
  match '/auth/:provider/callback', to: 'auth#callback', via: [:get, :post]  
  get 'auth/signout'
  
  resources :users, only: [:index, :new, :create, :edit, :update, :destroy]
  resources :stores, only: [:index, :new, :create, :edit, :update, :destroy]
  resources :products, only: [:index, :new, :create, :edit, :update, :destroy]
  resources :stocks, only: [:index]
  resources :stock_details, only: [:index, :new, :create, :edit, :destroy]
  resources :mng_tables, only:[:index]
  resources :output_mng_talbles, only:[:index]
  resources :distributes, only:[:new, :create]
  resources :product_select, only:[:index]
  resources :login, only:[:index]
  resources :sales_tables, only:[:index]
  
end
