Rails.application.routes.draw do
  match '/mt/:action(/:id(.:format))', :controller => 'turducken/mt'
end
   