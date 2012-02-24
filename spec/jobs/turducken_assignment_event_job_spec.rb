require 'spec_helper'

describe TurduckenAssignmentEventJob do
  before do
    @assignment = Fabricate(:assignment)
    Turducken::Assignment.should_receive(:find).and_return(@assignment)
    Resque.inline = true
  end
  def invoke
    # TurduckenAssignmentSubmittedJob.perform(@assignment.id.to_s)
    Resque.enqueue(TurduckenAssignmentEventJob, @assignment.id.to_s, :approved)
  end
  it 'should call handle_submitted on the assignment' do
    @assignment.should_receive(:handle_event).with(:approved)
    invoke
  end
end