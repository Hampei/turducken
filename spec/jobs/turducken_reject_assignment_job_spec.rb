require 'spec_helper'

describe TurduckenRejectAssignmentJob do
  before do
    @assignment = Fabricate(:assignment)
    Turducken::Assignment.should_receive(:find).and_return(@assignment)
    Resque.inline = true
  end
  def invoke
    Resque.enqueue(TurduckenRejectAssignmentJob, @assignment.id)
  end
  it 'should call approve! on the assignment' do
    @assignment.should_receive(:reject!)
    invoke
  end
  describe 'with an assignment with wrong state' do
    it 'should raise an Stateflow:NoTransitionFound exception' do
      @assignment.error!
      lambda{invoke}.should raise_error(Stateflow::NoTransitionFound)
    end
  end
end