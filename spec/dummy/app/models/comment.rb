class Comment < ActiveRecord::Base

  attr_protected

  state_machine :state, initial: :pending do
    event :accept do
      transition any => :accepted
    end

    event :refuse do
      transition any => :refused
    end
  end

  state_machine :likes_state, initial: :ok do
    event :like do
      transition ok: :liked
    end

    event :dislike do
      transition ok: :disliked
    end
  end
end
