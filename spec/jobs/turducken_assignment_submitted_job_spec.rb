require 'spec_helper'

describe TurduckenAssignmentSubmittedJob do
  before do
    @assignment = Fabricate(:assignment)
    Turducken::Assignment.should_receive(:find).and_return(@assignment)
    Resque.inline = true
  end
  def invoke
    # TurduckenAssignmentSubmittedJob.perform(@assignment.id.to_s)
    Resque.enqueue(TurduckenAssignmentSubmittedJob, @assignment.id.to_s)
  end
  it 'should call handle_submitted on the assignment' do
    @assignment.should_receive(:handle_submitted)
    invoke
  end
end