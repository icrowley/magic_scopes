require 'spec_helper'

describe MagicScopes do
  describe ".state_scopes" do
    subject { Comment }

    context "with arguments" do

      before { subject.state_scopes(:state) }

      %w(state likes_state).each do |scope|
        it { should respond_to("with_#{scope}") }
        it { should respond_to("without_#{scope}") }
      end

      Comment.state_machines[:state].states.map(&:name).each do |scope|
        it { should respond_to(scope) }
        it { should respond_to("not_#{scope}") }
      end
      Comment.state_machines[:likes_state].states.map(&:name).each do |scope|
        scope = "nil_likes_state" if scope.nil?
        it { should_not respond_to(scope) }
        it { should_not respond_to("not_#{scope}") }
      end
    end

    it "raises an error when argument is not an state machine represented column" do
      expect { subject.state_scopes(:best) }.to raise_error(MagicScopes::NoStateMachineError)
    end

    context "without args" do
      before { subject.state_scopes }

      it "defines all possible state scopes" do
        [:state, :likes_state].each do |sm|
          Comment.state_machines[sm].states.map(&:name).each do |state|
            state = "nil_#{sm}" if state.nil?
            should respond_to(state)
            should respond_to("not_#{state}")
          end
        end
      end

      it "does not define state scopes if column is not state one" do
        %w(title content user_id commentable_type created_at featured best).each do |attr|
          should_not respond_to(attr)
          should_not respond_to("not_#{attr}")
        end
      end
    end

    describe "fetching" do
      describe "state" do
        before do
          ['pending', 'accepted', 'refused'].each { |val| Comment.create(state: val) }
          subject.state_scopes(:state)
        end

        it "returns 1 for accepted" do
          subject.accepted.count.should == 1
        end

        it "returns 2 for not acepted" do
          subject.not_accepted.count.should == 2
        end
      end

      describe "likes_state" do
        before do
          [nil, 'liked', 'disliked'].each { |val| Comment.create(likes_state: val) }
          subject.state_scopes(:likes_state)
        end

        it "returns 1 for likes" do
          subject.liked.count.should == 1
        end

        it "returns 2 for not liked" do
          subject.not_liked.count.should == 2
        end

        describe "with/without" do
          it "returns 2 for with" do
            subject.with_likes_state.count.should == 2
          end

          it "returns 1 for without" do
            subject.without_likes_state.count.should == 1
          end
        end
      end
    end
  end
end
