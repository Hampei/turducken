Rails.application.routes.draw do
  match '/turducken/fake_external_submit', :controller => 'turducken/fake_external_submit', :action => :create
  match '/turducken/:action(/:id(.:format))', :controller => 'turducken/mt'
end
   