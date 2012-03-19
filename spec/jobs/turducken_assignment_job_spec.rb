require 'spec_helper'

describe TurduckenAssignmentJob do
  before do
    @assignment = Fabricate(:assignment)
    Turducken::Assignment.should_receive(:find).and_return(@assignment)
    Resque.inline = true
  end
  describe 'approve' do
    def invoke; Resque.enqueue(TurduckenAssignmentJob, 'approve', @assignment.id); end
    it 'should call approve! on the assignment' do
      @assignment.should_receive(:approve!)
      invoke
    end
    describe 'with an assignment with wrong state' do
      it 'should raise an Stateflow:NoTransitionFound exception' do
        @assignment.set_current_state(@assignment.machine.states[:rejected])
        lambda{invoke}.should raise_error(Stateflow::NoTransitionFound)
      end
    end
    describe 'with already approved assignment' do
      it 'should do nothing' do
        @assignment.set_current_state(@assignment.machine.states[:approved])
        @assignment.should_not_receive(:approve!)
        invoke
      end
    end
  end

  describe 'reject' do
    def invoke; Resque.enqueue(TurduckenAssignmentJob, 'reject', @assignment.id); end
    it 'should call reject! on the assignment' do
      @assignment.should_receive(:reject!)
      invoke
    end
    describe 'with an assignment with wrong state' do
      it 'should raise an Stateflow:NoTransitionFound exception' do
        @assignment.set_current_state(@assignment.machine.states[:approved])
        lambda{invoke}.should raise_error(Stateflow::NoTransitionFound)
      end
    end
    describe 'with already approved assignment' do
      it 'should do nothing' do
        @assignment.set_current_state(@assignment.machine.states[:rejected])
        @assignment.should_not_receive(:approve!)
        invoke
      end
    end
  end

  describe 'grant_bonus' do
    def invoke; Resque.enqueue(TurduckenAssignmentJob, 'grant_bonus', @assignment.id, '0.10', 'well done'); end
    it 'should call grant bonus with right arguments' do
      @assignment.should_receive(:grant_bonus).with(0.10, 'well done')
      invoke
    end
  end
end