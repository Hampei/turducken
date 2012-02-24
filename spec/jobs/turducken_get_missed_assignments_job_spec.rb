require 'spec_helper'

describe TurduckenGetMissedAssignmentJob do

  describe "perform" do
    before do
      @job = Fabricate(:job, :hit_id => '32A8TDZQEZYRV84XKZ4Z')
      @job.state = 'Running'
      @job.save

      @job.class.auto_approve false
      mock_turk_operation("GetAssignmentsForHIT")
      mock_turk_operation("ApproveAssignment")
      Resque.inline = true

      Turducken::Assignment.stub!(:create_from_mturk)
      Turducken::Assignment.create(:assignment_id => '32A8TDZQEZYRV84XKZ4ZBT6JT05DKJRZ1BC42YSZ')
    end
    after do
       @job.class.auto_approve true
    end
    it "should create the two assignments not yet in the database, but not the 1 that is in there." do
      Turducken::Assignment.should_receive(:create_from_mturk).exactly(2).times
      Resque.enqueue(TurduckenGetMissedAssignmentJob)
    end
  end
end
