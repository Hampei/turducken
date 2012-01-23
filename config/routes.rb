Rails.application.routes.draw do
  match '/turducken_surveys/show', :controller => 'turducken/surveys', :action => :show
  match '/mt/:action(/:id(.:format))', :controller => 'turducken/mt'
end
   