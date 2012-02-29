require 'spec_helper'

describe Job do
  describe 'default after creation' do
    before do
      @job = Fabricate(:job)
    end
  
    it 'should have the defaults set' do
      @job.hit_reward.should == 0.10
      @job.hit_num_assignments.should == 5
      @job.hit_lifetime_s.should == 3600
    end
  
    it 'should have the right title' do
      @job.hit_title.should == 'job title'
    end
  
    # it 'should have the right url' do
    #   @job.hit_question[0].should =~ %r~http://localhost/jobs~
    # end
  end

  describe 'finish transition' do
    before do
      @job = Fabricate(:job)
      @job.set_current_state(Job.machine.states[:running])
      Resque.stub(:enqueue)
    end
    def invoke; @job.finish; end

    it 'should enqueue the hit dispose job' do
      Resque.should_receive(:enqueue).with(TurduckenHITJob, :dispose, @job.hit_id)
      invoke
    end
    it 'should enqueue the job finished callback' do
      Resque.should_receive(:enqueue).with(TurduckenJobJob, :on_job_finished, @job.id)
      invoke
    end
    
  end


  describe 'check_progress!' do
    before do
      RTurk.stub(:ExtendHIT)
    end
    def invoke; @job.check_progress!; end

    it 'should raise an error when in beginning state' do
      @job = Fabricate(:job)
      lambda{invoke}.should raise_error
    end

    describe do
      before do
        @job = Fabricate(:job)
        @job.set_current_state(Job.machine.states[:finished])
      end
      it 'should return when state is already finished' do
        @job.should_not_receive(:more_assignments_needed?)
        invoke
      end
    end

    def create_job_with_assignments(options={})
      submitted = options.delete(:submitted) || 0
      approved = options.delete(:approved) || 0
      rejected = options.delete(:rejected) || 0

      @job = Fabricate(:job, options)
      @job.set_current_state(Job.machine.states[:running])

      submitted.times{ Fabricate(:assignment, :job => @job) }
      approved.times { Fabricate(:assignment, :job => @job, :state => 'approved') }
      rejected.times { Fabricate(:assignment, :job => @job, :state => 'rejected') }
    end
    
    def self.test_check_progress(options={})
      it "- should #{'not' unless options[:finish]}call finish" do
        @job.should_receive(:finish!).exactly(options[:finish] ? 1 : 0).times; invoke
      end
      it "- should #{'not' unless options[:extend]} extend the job" do
        RTurk.should_receive(:ExtendHIT).exactly(options[:extend] ? 1 : 0).times; invoke
      end
    end
    
    describe 'when not require_approved_assignments' do
      describe 'when not enough assignments handled' do
        it 'should not finish the job'
      end
    end
    describe 'when require_approved_assignments' do
      describe '- when all handled' do
        describe '- when all approved' do
          before { create_job_with_assignments(hit_num_assignments: 2, 
            approved: 2) }
          test_check_progress(:finish => true, :extend => false)
        end
        describe '- when enough approved, but some rejected' do
          before { create_job_with_assignments(hit_num_assignments: 3, require_approved_assignments: 2,
            approved: 2, rejected: 1) }
          test_check_progress(:finish => true, :extend => false)
        end
        describe '- when not enough approved (some rejected)' do
          before { create_job_with_assignments(hit_num_assignments: 3, require_approved_assignments: 2,
            approved: 1, rejected: 2) }
          test_check_progress(:finish => false, :extend => true)
        end
      end
      describe '- when not all handled' do
        describe '- but all submitted' do
          before { create_job_with_assignments(hit_num_assignments: 2, 
            approved: 1, submitted: 1) }
          test_check_progress(:finish => false, :extend => false)
        end
        describe '- and not all submitted' do
          before { create_job_with_assignments(hit_num_assignments: 2, 
            approved: 1) }
          test_check_progress(:finish => false, :extend => false)
        end
        describe '- and too many rejected to get required approved' do
          before { create_job_with_assignments(hit_num_assignments: 4, require_approved_assignments: 3,
            submitted: 1, rejected: 2) }
          test_check_progress(:finish => false, :extend => true)
        end
      end
    end
  end
  
  

end
