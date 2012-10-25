class Comment < ActiveRecord::Base

  attr_protected

  belongs_to :user
  belongs_to :commentable, polymorphic: true
  belongs_to :next


  state_machine :state, initial: :pending do
    event :accept do
      transition any => :accepted
    end

    event :refuse do
      transition any => :refused
    end
  end

  state_machine :likes_state do
    event :like do
      transition any => :liked
    end

    event :dislike do
      transition any => :disliked
    end
  end
end
