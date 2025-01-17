Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  get '/', to: 'orders#index'
  post '/orders/submit', to: 'orders#submit'
  resources :orders do
    member do
      get :success
      get :error
    end
  end
end
