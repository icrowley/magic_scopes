require 'spec_helper'

describe MagicScopes do
  describe "association scopes" do
    subject { Comment }

    describe "generated scopes" do
      let(:attrs) { [:user, :commentable, :next] }
      before { subject.magic_scopes(*attrs) }

      it "defines all possible association scopes" do
        attrs.each do |attr|
          should respond_to("for_#{attr}")
          should respond_to("not_for_#{attr}")
        end
      end

      it "does not define association scopes with non foreign column types" do
        (MagicScopes::ScopesBuilder.new(subject).send(:all_possible_attrs) - attrs).each do |attr|
          should_not respond_to("for_#{attr}")
          should_not respond_to("not_for_#{attr}")
        end
      end
    end

    describe "fetching" do
      let(:user) { User.create }

      context "simple association" do
        before do
          subject.magic_scopes(:user)
          subject.create(user_id: user.id)
          2.times { subject.create }
        end

        it "returns 1 for user instance" do
          subject.for_user(user).count.should == 1
        end

        it "returns 1 for user id" do
          subject.for_user(user.id).count.should == 1
        end

        context "with multiple models" do
          let(:user2) { User.create }
          before { subject.create(user_id: user2.id) }

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

          it "raises error when unexpected argument passes" do
            expect { subject.for_user([user, user2.id, 'bogus']) }.to raise_error(ArgumentError)
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
          subject.magic_scopes(:commentable)
          subject.create(commentable: user)
          2.times { subject.create }
        end

        it "returns 1 for user instance" do
          subject.for_commentable(user).count.should == 1
        end

        context "with multiple models" do
          let(:user2) { User.create }
          before { subject.create(commentable: user2) }

          it "accepts multiple arguments" do
            subject.for_commentable(user, id: user2.id, type: user2.class.name).count.should == 2
          end

          it "accepts multiple arguments for negative scope" do
            subject.not_for_commentable(user, id: user2.id, type: user2.class.name).count.should == 2
          end

          it "accepts arrays with user instances" do
            subject.for_commentable([user, user2]).count.should == 2
          end

          it "raises error when unexpected argument passes" do
            expect { subject.for_commentable([user, 'bogus']) }.to raise_error(ArgumentError)
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
