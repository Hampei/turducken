require 'spec_helper'

describe Turducken::Assignment do
  before do
    @job = Fabricate(:job)
    @assignment = Fabricate(:assignment, job: @job)
  end

  # describe "create_from_mturk" do
  #   We test this from get_assignment_results_spec
  # end
  
  describe 'handle_submitted' do
    before do
      mock_turk_operation("ApproveAssignment")
      Resque.stub(:enqueue)
    end
    def invoke; @assignment.handle_submitted; end
    
    it 'should check state is correct' do
      @assignment.error!
      invoke
      @job.nro_assignments_finished.should == 0
    end
    it 'should have called the on_assignment_submitted' do
      invoke
      @job.nro_assignments_finished.should == 1
    end
    describe 'with testable bad content' do
      before do
        mock_turk_operation("RejectAssignment")
        @assignment.answers['tweet'] = 'this content has illegal stuff'
      end
      it 'should reject the assignment' do
        invoke
        @assignment.rejected?.should be_true
      end
      it 'should enqueue the rejected callback' do
        Resque.should_receive(:enqueue).with(TurduckenAssignmentEventJob, @assignment.id, :rejected)
        invoke
      end
      it 'should enqueue the check_progress job' do
        Resque.should_receive(:enqueue).with(TurduckenJobJob, :check_progress, @job.id)
        invoke
      end
    end
    describe 'with unexpected errors being thrown' do
      before do
        @assignment.answers['tweet'] = 'this content will cause and unexpected error'
      end
      it 'should set the assignment in the error state' do
        invoke
        @assignment.errored?.should be_true
      end
      it 'should set error and backtrace info' do
        invoke
        @assignment.extra['error'].should_not be_nil
        @assignment.extra['backtrace'].should_not be_nil
      end
    end
    describe 'with auto_approve and correct content' do
      it 'should have approved the assignment' do
        invoke
        @assignment.approved?.should be_true
      end
      it 'should have told amazon about the approvement' do
        invoke
        WebMock.should have_requested(:post, /amazonaws.com/).with {|req| req.body =~ /Operation=ApproveAssignment/ }
      end
      it 'should enqueue the approved callback' do
        Resque.should_receive(:enqueue).with(TurduckenAssignmentEventJob, @assignment.id, :approved)
        invoke
      end
      it 'should enqueue the check_progress job' do
        Resque.should_receive(:enqueue).with(TurduckenJobJob, :check_progress, @job.id)
        invoke
      end
    end
    describe 'without auto_approve' do
      before { @job.class.auto_approve false }
      after { @job.class.auto_approve true }

      it 'should set the state to pending_approval' do
        invoke
        @assignment.pending_approval?.should be_true
      end
    end
  end
  
  describe 'handle_event' do
    def invoke; @assignment.handle_event(:approved); end
    it 'should invoke the events callback' do
      @job.should_receive(:do_approved).with(@assignment)
      invoke
    end
  end
end
