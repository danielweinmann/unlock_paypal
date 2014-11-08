Rails.application.routes.draw do

  resources :paypal_contributions, controller: 'unlock_paypal/contributions', only: [:create, :edit, :update], path: '/paypal' do
    member do
      put :activate
      put :suspend
      get :error
    end
    collection do
      post :ipn
    end
  end

end
