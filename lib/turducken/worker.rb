module Turducken
    module Worker
      def self.included(model)
        model.class_eval do
          field :turk_id, :type => String

          validates_presence_of :turk_id
          validates_uniqueness_of :turk_id

          has_many :assignments, :class_name => 'Turducken::Assignment'
        end
      end
  end
end
