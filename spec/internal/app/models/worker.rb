class Worker
  include Mongoid::Document
  include Mongoid::Timestamps
  include Turducken::Worker

  field :sex, :type => String

end
