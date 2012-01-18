module Turducken
  class MturkEvent
    include Mongoid::Document
    field :type,          :type => String
    field :hit_type_id,   :type => String
    field :hit_id,        :type => String
    field :assignment_id, :type => String
    field :time,          :type => String
  end
end
