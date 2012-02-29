require 'spec_helper'

describe TurduckenJobJob do
  before do
    @job = Fabricate(:job)
    @job.set_current_state(@job.machine.states[:running])
    Turducken::Job.should_receive(:find).and_return(@job)
    Resque.inline = true
  end
  describe 'check_progress!' do
    before do
    end
    def invoke
      Resque.enqueue(TurduckenJobJob, :check_progress, @job.id)
    end
    it 'should call check_progress on the job' do
      @job.should_receive(:check_progress!)
      invoke
    end
  end
  describe 'on_job_progress' do
    def invoke
      Resque.enqueue(TurduckenJobJob, :on_job_finished, @job.id)
    end
    it 'should call on_job_progress on the job' do
      @job.should_receive(:on_job_finished)
      invoke
    end
  end
end
