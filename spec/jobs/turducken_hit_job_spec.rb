require 'spec_helper'

describe TurduckenHITJob do
  before do
    @hit_id = 'A5F76B'
    Resque.inline = true
  end
  describe 'dispose' do
    before do
    end
    def invoke
      Resque.enqueue(TurduckenHITJob, :dispose, @hit_id)
    end
    it 'call amazon to dispose the hit' do
      RTurk.should_receive(:DisposeHIT).with(hit_id: @hit_id)
      invoke
    end
  end
end
