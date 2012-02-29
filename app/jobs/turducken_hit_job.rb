class TurduckenHITJob
  @queue = :mturk

  def self.perform(action, hit_id)
    case action.to_sym
    when :dispose
      RTurk::DisposeHIT(hit_id: hit_id)
    end
  end
end
