require 'spec_helper'

describe Job do
  before do
    @job = Job.new
  end
  
  it 'should have the defaults set' do
    @job.hit_reward.should == 0.10
    @job.hit_num_assignments.should == 5
    @job.hit_lifetime_s.should == 3600
  end
  
  it 'should have the right title' do
    @job.hit_title.should == 'job title'
  end
  
  # it 'should have the right url' do
  #   @job.hit_question[0].should =~ %r~http://localhost/jobs~
  # end
  
end