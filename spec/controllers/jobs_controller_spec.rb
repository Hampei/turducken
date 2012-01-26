require 'spec_helper'

def param_hash(override = {})
  {"assignmentId"=>"ASSID", "hitId"=>"25RZ6KW4ZMAZF1UU9MH0VNNVRDD7GV", "workerId"=>"WORKID", "turkSubmitTo"=>"https://workersandbox.mturk.com", "id"=>"49"}.merge!(override)
end

describe JobsController do
  render_views
  let(:page) { Capybara::Node::Simple.new(@response.body) }

  describe 'job hit_question (tested here, since routes are needed)' do
    it 'should have the right url' do
      job = Fabricate(:job)
      job.hit_question[0].should =~ %r~http://localhost/jobs~
    end
  end

  describe "GET :show with assignmetId" do
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

    it "should show the created fields" do
      page.should have_xpath("//input[@type='radio' and @value='Female']")
    end

    it "should have the fields enabled" do
      page.should_not have_xpath("//input[@type='radio' and @value='Female']/@disabled")
    end

    it 'should have real data' do
      page.should have_content('real data')
    end
  end
  
  describe "GET :show without assignmentId" do
    before do
      job = Fabricate(:job)
      
      get :show, param_hash({:hitId => job.hit_id, :assignmentId => nil})
    end
    
    it 'should have example data' do
      page.should have_content('example data')
    end
    
    it 'should have a disable form' do
      page.should have_xpath("//input[@type='radio' and @value='Female']/@disabled")
    end
  end
  
  describe "round trip" do
    before do
      mock_turk_operation("CreateHIT")
      mock_turk_operation("SetHITTypeNotification")
      Resque.inline = true
      @job = Fabricate(:job)
    end
    
    it 'should post to the right ExternalURL' do
      reg = CGI::escape("ExternalURL>http://localhost/jobs/#{@job.id}")
      WebMock.should have_requested(:post, /amazonaws.com/).with {|req| req.body =~ %r~#{reg}~ }
    end
    
    it 'should post the right frameheight' do
      reg = CGI::escape('FrameHeight>300')
      WebMock.should have_requested(:post, /amazonaws.com/).with {|req| req.body =~ %r~#{reg}~ }
    end
  end

end


# <input type="hidden" id="assignmentId" name="assignmentId" value="2BLHV8ER9Y8TL4LPNZD5RFHS4U9R4K"/><input type="hidden" id="workerId" name="workerId" value="A3LP6T9VE9EKJQ"/><input type="hidden" id="turkSubmitTo" name="turkSubmitTo" value="https%3A%2F%2Fwww.mturk.com"/><input type="hidden" id="id" name="id" value="49"/><input type="hidden" id="hitId" name="hitId" value="HITID"/>

# <input id="assignmentId" name="assignmentId" type="hidden" value="2BLHV8ER9Y8TL4LPNZD5RFHS4U9R4K" /><input id="workerId" name="workerId" type="hidden" value="A3LP6T9VE9EKJQ" /><input id="turkSubmitTo" name="turkSubmitTo" type="hidden" value="https://www.mturk.com" /><input id="id" name="id" type="hidden" value="49" /><input id="hitId" name="hitId" type="hidden" value="HITID" />
