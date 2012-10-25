require 'spec_helper'

describe MagicScopes do
  describe ".num_scopes" do
    subject { User }

    context "with arguments" do
      before { subject.num_scopes(:age, :weight) }
      %w(age weight).each do |scope|
        it { should respond_to("with_#{scope}") }
        it { should respond_to("without_#{scope}") }
        it { should respond_to("#{scope}_eq") }
        it { should respond_to("#{scope}_gt") }
        it { should respond_to("#{scope}_lt") }
        it { should respond_to("#{scope}_gte") }
        it { should respond_to("#{scope}_lte") }
        it { should respond_to("#{scope}_ne") }
        it { should respond_to("by_#{scope}") }
        it { should respond_to("by_#{scope}_desc") }
      end
      it { should_not respond_to(:height) }
    end

    context "without arguments" do

      before { subject.num_scopes }

      it "defines all possible num scopes" do
        %w(age weight height dec).each do |attr|
          should respond_to("with_#{attr}")
        end
      end

      it "does not define num scopes with non num column types" do
        %w(ref_id testable_id moderator about created_at last_name rating).each do |attr|
          should_not respond_to("with_#{attr}")
        end
      end
    end

    describe "fetching" do
      before do
        (1..4).each { |val| User.create(age: val) }
        subject.num_scopes(:age)
      end

      it "returns 1 for age" do
        subject.with_age(2).count.should == 1
      end

      it "returns 2 for age with array" do
        subject.with_age([2, 3]).count.should == 2
      end

      it "accepts multiple arguments" do
        subject.with_age(2, 3).count.should == 2
      end

      it "accepts multiple arguments for negative scope" do
        subject.age_ne(1, 2, 3).count.should == 1
      end

      it "returns 1 for eq" do
        subject.age_eq(2).count.should == 1
      end

      it "returns 1 for lt" do
        subject.age_lt(2).count.should == 1
      end

      it "returns 2 for lte" do
        subject.age_lte(2).count.should == 2
      end

      it "returns 2 for gt" do
        subject.age_gt(2).count.should == 2
      end

      it "returns 3 for gte" do
        subject.age_gte(2).count.should == 3
      end

      it "returns 3 for ne" do
        subject.age_ne(2).count.should == 3
      end

      it "returns 2 for ne with array" do
        subject.age_ne([2, 4]).count.should == 2
      end
    end

    describe "by scopes" do
      before do
        [2,4,5,1].each { |n| User.create(age: n) }
        subject.num_scopes(:age)
      end

      it "properly sorts asc" do
        subject.by_age.map(&:age).should == [1,2,4,5]
      end

      it "properly sorts desc" do
        subject.by_age_desc.map(&:age).should == [5,4,2,1]
      end

      describe "with/without" do
        before { User.create }

        it "returns 4 for with" do
          subject.with_age.count.should == 4
        end

        it "returns 1 for without" do
          subject.without_age.count.should == 1
        end
      end
    end
  end
end
