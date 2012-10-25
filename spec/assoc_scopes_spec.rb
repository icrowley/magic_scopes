require 'spec_helper'

describe MagicScopes do
  describe ".assoc_scopes" do
    subject { Comment }

    context "with arguments" do
      before { subject.assoc_scopes(:user, :commentable) }
      %w(user commentable).each do |scope|
        it { should respond_to("for_#{scope}") }
        it { should respond_to("not_for_#{scope}") }
      end
      it { should_not respond_to(:next) }
    end

    it "raises an error when argument is not an association" do
      expect { subject.assoc_scopes(:state) }.to raise_error(MagicScopes::NoAssociationError)
    end

    context "without arguments" do

      before { subject.assoc_scopes }

      it "defines all possible association scopes" do
        %w(user commentable next).each do |attr|
          should respond_to("for_#{attr}")
        end
      end

      it "does not define association scopes with non foreign column types" do
        %w(title content state likes_state featured hidden best).each do |attr|
          should_not respond_to("for_#{attr}")
        end
      end
    end

    describe "fetching" do
      let(:user) { User.create }

      context "simple association" do
        before do
          Comment.create(user_id: user.id)
          2.times { Comment.create }
          subject.assoc_scopes(:user)
        end

        it "returns 1 for user instance" do
          subject.for_user(user).count.should == 1
        end

        it "returns 1 for user id" do
          subject.for_user(user.id).count.should == 1
        end

        context "with multiple models" do
          let(:user2) { User.create }
          before { Comment.create(user_id: user2.id) }

          it "accepts multiple arguments" do
            subject.for_user(user, user2.id).count.should == 2
          end

          it "accepts multiple arguments for negative scope" do
            subject.not_for_user(user, user2.id).count.should == 2
          end

          it "accepts arrays with user ids" do
            subject.for_user([user.id, user2.id]).count.should == 2
          end

          it "accepts arrays with user instances" do
            subject.for_user([user, user2]).count.should == 2
          end

          it "accepts arrays with user instances and user ids" do
            subject.for_user([user, user2.id, '3']).count.should == 2
          end
        end

        it "returns 2 for non user instance" do
          subject.not_for_user(user).count.should == 2
        end

        it "returns 2 for non user id" do
          subject.not_for_user(user.id).count.should == 2
        end
      end

      context "polymorphic association" do
        before do
          Comment.create(commentable: user)
          2.times { Comment.create }
          subject.assoc_scopes(:commentable)
        end

        it "returns 1 for user instance" do
          subject.for_commentable(user).count.should == 1
        end

        context "with multiple models" do
          let(:user2) { User.create }
          before { Comment.create(commentable: user2) }

          it "accepts multiple arguments" do
            subject.for_commentable(user, id: user2.id, type: user2.class.name).count.should == 2
          end

          it "accepts multiple arguments for negative scope" do
            subject.not_for_commentable(user, id: user2.id, type: user2.class.name).count.should == 2
          end

          it "accepts arrays with user instances" do
            subject.for_commentable([user, user2]).count.should == 2
          end
        end

        it "returns 2 for non user instance" do
          subject.not_for_commentable(user).count.should == 2
        end

        it "returns 1 for user id and type" do
          subject.for_commentable(id: user.id, type: user.class.name).count.should == 1
        end
      end
    end
  end
end
