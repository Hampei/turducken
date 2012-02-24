require 'spec_helper'

describe TurduckenCheckJobProgressJob do
  before do
    @job = Fabricate(:job)
    Turducken::Job.should_receive(:find).and_return(@job)
    Resque.inline = true
  end
  def invoke
    Resque.enqueue(TurduckenCheckJobProgressJob, @job.id)
  end
  it 'should call approve! on the assignment' do
    @job.should_receive(:check_progress!)
    invoke
  end
end
