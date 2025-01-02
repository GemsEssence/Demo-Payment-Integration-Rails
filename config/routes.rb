Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Define root path
  root "orders#index"  # This will set the root path to the orders index page

  post '/orders/submit', to: 'orders#submit'
  resources :orders do
    member do
      get :success
      get :error
    end

    collection do
      get :phone_pe_redirect
      post :phone_pe_redirect
  end
  end

  post 'orders/paypal/create_payment'  => 'orders#paypal_create_payment', as: :paypal_create_payment
  post 'orders/paypal/execute_payment'  => 'orders#paypal_execute_payment', as: :paypal_execute_payment

  post 'orders/paypal/create_subscription'  => 'orders#paypal_create_subscription', as: :paypal_create_subscription
  post 'orders/paypal/execute_subscription'  => 'orders#paypal_execute_subscription', as: :paypal_execute_subscription
end
