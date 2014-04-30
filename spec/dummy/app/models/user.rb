class User < ActiveRecord::Base

  belongs_to :ref
  belongs_to :specable, polymorphic: true

  state_machine :state, initial: :pending do
    event :accept do
      transition any => :accepted
    end

    event :refuse do
      transition any => :refused
    end
  end
end
