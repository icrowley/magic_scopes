require 'spec_helper'

describe MagicScopes do
  describe "num scopes" do
    subject { User }

    describe "generated scopes" do
      let(:attrs) { [:age, :weight, :height, :dec] }
      before { subject.magic_scopes(*attrs) }

      it "defines all possible num scopes" do
        attrs.each do |attr|
          should respond_to("with_#{attr}")
          should respond_to("without_#{attr}")
          should respond_to("#{attr}_eq")
          should respond_to("#{attr}_gt")
          should respond_to("#{attr}_lt")
          should respond_to("#{attr}_gte")
          should respond_to("#{attr}_lte")
          should respond_to("#{attr}_ne")
          should respond_to("by_#{attr}")
          should respond_to("by_#{attr}_desc")
        end
      end

      it "does not define num scopes with non num column types" do
        (MagicScopes::ScopesBuilder.new(subject).send(:all_possible_attributes) - attrs).each do |attr|
          should_not respond_to("with_#{attr}")
          should_not respond_to("without_#{attr}")
          should_not respond_to("#{attr}_eq")
          should_not respond_to("#{attr}_gt")
          should_not respond_to("#{attr}_lt")
          should_not respond_to("#{attr}_gte")
          should_not respond_to("#{attr}_lte")
          should_not respond_to("#{attr}_ne")
          should_not respond_to("by_#{attr}")
          should_not respond_to("by_#{attr}_desc")
        end
      end
    end

    describe "fetching" do
      before do
        subject.magic_scopes(:age)
        (1..4).each { |val| subject.create(age: val) }
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
        subject.magic_scopes(:age)
        [2,4,5,1].each { |n| subject.create(age: n) }
      end

      it "properly sorts asc" do
        subject.by_age.map(&:age).should == [1,2,4,5]
      end

      it "properly sorts desc" do
        subject.by_age_desc.map(&:age).should == [5,4,2,1]
      end

      describe "with/without" do
        before { subject.create }

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
