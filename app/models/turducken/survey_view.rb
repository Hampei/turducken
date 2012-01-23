module Turducken
  class SurveyView
    include Mongoid::Document
    include Mongoid::Timestamps

    field :hit_id, :type => String
    field :assignment_id, :type => String
    field :ip_address, :type => String
    field :browser, :type => String
  end
end
