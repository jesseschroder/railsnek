Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  post '/start', to: 'game#create'
  post '/end', to: 'game#destroy'
  post '/move', to: 'movement#create'

  root 'application#index'
end
