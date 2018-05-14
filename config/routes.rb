Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :games, only: [:create, :update], format: :json do
    resources :invitations, only: [:create, :update, :destroy], format: :json
  end

  post 'authenticate', to: 'authentication#authenticate'
end
