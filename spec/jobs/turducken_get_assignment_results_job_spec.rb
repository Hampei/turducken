require 'spec_helper'

describe TurduckenGetAssignmentResultsJob do

  describe "perform" do
    before do
      @job = Fabricate(:job, :hit_id => '32A8TDZQEZYRV84XKZ4Z')
      Turducken::Job.should_receive(:where).with(:hit_id => '32A8TDZQEZYRV84XKZ4Z').and_return([@job])
      mock_turk_operation("GetAssignmentsForHIT")
      mock_turk_operation("ApproveAssignment")
      @assignment_id = '32A8TDZQEZYRV84XKZ4ZBT6JT05DKJRZ1BC42YSZ'
    end
    def invoke
      TurduckenGetAssignmentResultsJob.perform(@job.hit_id, @assignment_id)
    end

    it "should have created the assignment" do
      invoke
      Turducken::Assignment.where(:assignment_id => @assignment_id).exists?.should be_true
    end
    it 'should have state submitted' do
      invoke
      Turducken::Assignment.where(:assignment_id => @assignment_id).first.state.should == 'submitted'
    end
    it 'should have created a worker' do
      invoke
      Worker.where(:turk_id => 'ADOJP7RNRYAFG').exists?.should be_true
    end
    it 'should enqueue the assignment submitted callback job with the new assignment' do
      Resque.should_receive(:enqueue) do |arg1, arg2|
        arg1.should == TurduckenAssignmentSubmittedJob
        arg2.should == Turducken::Assignment.where(:assignment_id => @assignment_id).first.id
      end
      invoke
    end
  end

end
