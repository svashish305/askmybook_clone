Rails.application.routes.draw do
  resources :questions
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "questions#index"

  post "/questions", to: "questions#create"

  resources :resemble

  post "/resemble/callback", to: "resemble#callback"
end
