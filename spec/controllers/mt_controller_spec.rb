require 'spec_helper'

describe Turducken::MtController do

  describe "GET 'notifications'" do
    it "should be successful" do
      get 'notifications'
      response.should be_success
    end
  end

end
