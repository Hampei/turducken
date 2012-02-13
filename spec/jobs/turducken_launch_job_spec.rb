require 'spec_helper'

describe TurduckenLaunchJob do
  before do
    @job = Fabricate(:job)
    mock_turk_operation("CreateHIT") # hit_id: GBHZVQX3EHXZ2AYDY2T0
    mock_turk_operation("SetHITTypeNotification")
    Resque.inline = true
    Resque.enqueue(TurduckenLaunchJob, @job.id)
    @job.reload
  end
  
  it 'should set hit_id, hit_url and hit_type_id' do
    @job.hit_id.should == 'GBHZVQX3EHXZ2AYDY2T0'
    @job.hit_url.should == 'http://workersandbox.mturk.com/mturk/preview?groupId=NYVZTQ1QVKJZXCYZCZVZ'
    @job.hit_type_id.should == 'NYVZTQ1QVKJZXCYZCZVZ'
  end
  
  it 'should have asked for notifications from amazon' do
    WebMock.should have_requested(:post, /amazonaws.com/).with {|req| req.body =~ /Operation=SetHITTypeNotification/ && req.body =~ /#{@job.hit_type_id}/  }
  end
  
  it 'should have added qualification country UK (dynamic qualification)' do
    WebMock.should have_requested(:post, /amazonaws.com/).with {|req| req.body =~ /Country=UK/ && req.body =~ /QualificationTypeId=00000000000000000071/ }
  end
  
  it 'should have added qualification approval_rate>60' do
    WebMock.should have_requested(:post, /amazonaws.com/).with {|req| req.body =~ /IntegerValue=60/ && req.body =~ /QualificationTypeId=000000000000000000L0/  }
  end
  
end