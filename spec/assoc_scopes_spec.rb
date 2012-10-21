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
        %w(user commentable parent).each do |attr|
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
          subject.assoc_scopes(:user)
        end

        it "returns 1 for user instance" do
          subject.for_commentable(user).count.should == 1
        end

        it "returns 1 for user id" do
          subject.for_commentable(user.id).count.should == 1
        end

        it "returns 2 for non user instance" do
          subject.not_for_commentable(user).count.should == 2
        end

        it "returns 1 for user id and type" do
          subject.for_commentable(user.id, user.class.name).count.should == 1
        end

        it "returns 1 for user id" do
          subject.for_commentable(user.id).count.should == 1
        end

        it "returns 1 for user type" do
          subject.for_commentable(user.class.name).count.should == 1
        end
      end
    end
  end
end