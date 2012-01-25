require 'spec_helper'

describe TurduckenGetAssignmentResultsJob do

  describe "perform" do
    before do
      @job = Fabricate(:job, :hit_id => '32A8TDZQEZYRV84XKZ4Z')
      mock_turk_operation("GetAssignmentsForHIT")
      mock_turk_operation("ApproveAssignment")
      Resque.inline = true
    end
    describe "with auto_approve on" do
      before do
        @assignment_id = '32A8TDZQEZYRV84XKZ4ZBT6JT05DKJRZ1BC42YSZ'
        Resque.enqueue(TurduckenGetAssignmentResultsJob, @job.hit_id, @assignment_id)
      end

      it "should have created the assignment" do
        Turducken::Assignment.where(:assignment_id => @assignment_id).exists?.should be_true
      end
      it 'should have approved the assignment' do
        Turducken::Assignment.where(:assignment_id => @assignment_id).first.approved?.should be_true
      end
      it 'should have told amazon about the approvement' do
        WebMock.should have_requested(:post, /amazonaws.com/).with {|req| req.body =~ /Operation=ApproveAssignment/ }
      end
      it 'should have created a worker' do
        Worker.where(:turk_id => 'ADOJP7RNRYAFG').exists?.should be_true
      end
    end
    describe "with auto_approve off" do
      before do
        @assignment_id = '32A8TDZQEZYRV84XKZ4ZBT6JT05DKJRZ1BC42YSX'
        @job.class.auto_approve false
        Resque.enqueue(TurduckenGetAssignmentResultsJob, @job.hit_id, @assignment_id)
      end
      after do
         @job.class.auto_approve true
       end
      it 'should not approve the assignment if auto_approve is off' do
        Turducken::Assignment.where(:assignment_id => @assignment_id).first.approved?.should be_false
      end
    end
    describe "with auto_approve off" do
      before do
        @assignment_id = '32A8TDZQEZYRV84XKZ4ZBT6JT05DKJRZ1BC42YSY'
        mock_turk_operation('RejectAssignment')
        Resque.enqueue(TurduckenGetAssignmentResultsJob, @job.hit_id, @assignment_id)
      end
      it 'should reject the assignment if AssignmentException is raised in on_assignment_finished' do
        Turducken::Assignment.where(:assignment_id => @assignment_id).first.rejected?.should be_true
      end
      it 'should have told amazon about the rejection' do
        WebMock.should have_requested(:post, /amazonaws.com/).with {|req| req.body =~ /Operation=RejectAssignment/ and req.body =~ /word\+illegal\+is\+illegal/}
      end
    end
  end

end
