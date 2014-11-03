Rails.application.routes.draw do

  resources :moip_contributions, controller: 'unlock_moip/contributions', only: [:create, :update], path: '/moip' do
    member do
      put :activate
      put :suspend
    end
  end

end
