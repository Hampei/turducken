class JobsController < ActionController::Base
  include Turducken::Controller
  
  def show
    @model = Worker.new
    if is_preview?
      @extra_info = "example data"
    else
      @extra_info = "real data"
    end

    render 'turducken/job'
  end
end
