Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  mount Riiif::Engine => '/image', as: 'riiif'

  get '/annotationlist/:project/:object', to: 'annotation_list#show'

end
