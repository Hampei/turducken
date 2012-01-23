require 'spec_helper'

describe TurduckenGetAssignmentResultsJob do

  describe "perform" do
    before do
      @job = Fabricate(:job, :hit_id => '32A8TDZQEZYRV84XKZ4Z')
      @assignment_id = '32A8TDZQEZYRV84XKZ4ZBT6JT05DKJRZ1BC42YSZ'
      mock_turk_operation("GetAssignmentsForHIT")
      mock_turk_operation("ApproveAssignment")
      Resque.inline = true
      Resque.enqueue(TurduckenGetAssignmentResultsJob, @job.hit_id, @assignment_id)
    end
    it "should have created the assignment" do
      Turducken::Assignment.where(:assignment_id => @assignment_id).exists?.should be_true
    end
    it 'should have approved the assignment' do
      Turducken::Assignment.where(:assignment_id => @assignment_id).first.approved?.should be_true
    end
    it 'should have created a worker' do
      Worker.where(:turk_id => 'ADOJP7RNRYAFG').exists?.should be_true
    end
  end

end
