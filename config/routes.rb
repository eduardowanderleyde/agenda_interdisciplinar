Rails.application.routes.draw do
  get 'sortear/index'
  root 'home#index'

  devise_for :users

  resources :professionals do
    member do
      get :available_times
      get :schedule, to: 'professionals#schedule', as: :schedule
    end
  end

  resources :appointments do
    resources :evolutions, shallow: true
  end

  resources :evolutions, only: %i[index show edit update destroy]
  resources :patients
  resources :specialties
  resources :suggestions, only: [:index] do
    collection do
      get :dias
      get :horarios
      get :especialidades
      get :sugestoes
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  get 'organizar', to: 'organizar#index', as: :organizar
  post 'organizar/escolher', to: 'organizar#escolher', as: :escolher_agenda
  get 'organizar/confirmar', to: 'organizar#confirmar', as: :confirmar_agenda
end
