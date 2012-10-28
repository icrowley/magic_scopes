require 'spec_helper'

describe MagicScopes do
  describe "state scopes" do
    subject { Comment }

    describe "generated scopes" do
      let(:attrs) { [:state, :likes_state] }

      context "with generated attributes list" do
        before { subject.magic_scopes }

        it "defines all possible state scopes" do
          attrs.each do |sm|
            should respond_to("with_#{sm}")
            should respond_to("without_#{sm}")

            subject.state_machines[sm].states.map(&:name).each do |state|
              if state
                should respond_to(state)
                should respond_to("not_#{state}")
              end
            end
          end
        end
      end

      context "with state attributes passed" do
        before { subject.magic_scopes(*attrs) }

        it "defines all possible state scopes" do
          attrs.each do |sm|
            should respond_to("with_#{sm}")
            should respond_to("without_#{sm}")

            subject.state_machines[sm].states.map(&:name).each do |state|
              if state
                should respond_to(state)
                should respond_to("not_#{state}")
              end
            end
          end
        end
      end

      it "does not define state scopes if column is not state one" do
        builder = MagicScopes::ScopesBuilder.new(subject)
        (builder.send(:all_possible_attrs) - builder.send(:extract_states_from_attrs, attrs)).each do |attr|
          should_not respond_to(attr)
          should_not respond_to("not_#{attr}")
        end
      end

      it "does not respond to scopes for state columns" do
        attrs.each do |attr|
          should_not respond_to(attr)
          should_not respond_to("not_#{attr}")
        end
      end
    end

    describe "fetching" do
      describe "state" do
        before do
          subject.magic_scopes(:state)
          ['pending', 'accepted', 'refused'].each { |val| subject.create(state: val) }
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
          subject.magic_scopes(:likes_state)
          [nil, 'liked', 'disliked'].each { |val| subject.create(likes_state: val) }
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
