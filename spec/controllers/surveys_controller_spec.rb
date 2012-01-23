require 'spec_helper'

def param_hash(override = {})
  {"assignmentId"=>"ASSID", "hitId"=>"25RZ6KW4ZMAZF1UU9MH0VNNVRDD7GV", "workerId"=>"WORKID", "turkSubmitTo"=>"https://workersandbox.mturk.com", "id"=>"49"}.merge!(override)
end

describe Turducken::SurveysController do
  render_views
  let(:page) { Capybara::Node::Simple.new(@response.body) }

  describe "GET :show" do
    before do
      job = Fabricate(:job)
      
      get :show, param_hash({:hitId => job.hit_id})
    end
    
    it 'should post to the right url' do
      page.should have_xpath("//form/@action", :text => 'https://workersandbox.mturk.com/mturk/externalSubmit')
    end
    
    it 'should include the hitId, workerId and assignmentId  in a hidden field.' do
      page.should have_xpath("//input[@type='hidden' and @id='hitId']/@value", :text => 'HITID')
      page.should have_xpath("//input[@type='hidden' and @id='workerId']/@value", :text => 'WORKID')
      page.should have_xpath("//input[@type='hidden' and @id='assignmentId']/@value", :text => 'ASSID')
    end

    it "displays a flash notice" do
      page.should have_xpath("//input[@type='radio' and @value='Female']")
    end

  end


end


# <input type="hidden" id="assignmentId" name="assignmentId" value="2BLHV8ER9Y8TL4LPNZD5RFHS4U9R4K"/><input type="hidden" id="workerId" name="workerId" value="A3LP6T9VE9EKJQ"/><input type="hidden" id="turkSubmitTo" name="turkSubmitTo" value="https%3A%2F%2Fwww.mturk.com"/><input type="hidden" id="id" name="id" value="49"/><input type="hidden" id="hitId" name="hitId" value="HITID"/>

# <input id="assignmentId" name="assignmentId" type="hidden" value="2BLHV8ER9Y8TL4LPNZD5RFHS4U9R4K" /><input id="workerId" name="workerId" type="hidden" value="A3LP6T9VE9EKJQ" /><input id="turkSubmitTo" name="turkSubmitTo" type="hidden" value="https://www.mturk.com" /><input id="id" name="id" type="hidden" value="49" /><input id="hitId" name="hitId" type="hidden" value="HITID" />
