Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  root 'products#index'

  resources :products, only: [:index, :show]
  resources :categories, only: [:show]

  resource :cart, only: [:show, :destroy] do
    collection do
      get :checkout
      delete "remove_item/:id", action: :remove_item, as: :remove_item
    end
  end

  resources :orders, except: [:new, :edit, :update, :destroy] do
    member do
      delete :cancel #orders/1/cancel
      post :pay
      get :pay_confirm
    end

    collection do
      get :confirm #orders/confirm
    end
  end

  namespace :admin do 
    root 'products#index'                              
    resources :products, except: [:show]
    resources :vendors, except: [:show]
    resources :categories, except: [:show] do
      collection do
        put :sort
      end
    end
  end

  namespace :api do
    namespace :v1 do
      post 'subscribe', to: 'utils#subscribe'
      post 'cart', to: 'utils#cart'
      patch 'cart/:id', to: 'utils#update_cart'
    end
  end
end
