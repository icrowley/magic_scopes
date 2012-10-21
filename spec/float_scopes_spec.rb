require 'spec_helper'

describe MagicScopes do
  describe ".float_scopes" do
    subject { User }

    context "with arguments" do
      before { subject.float_scopes(:floato, :floatum) }
      %w(floato floatum).each do |scope|
        it { should_not respond_to(scope) }
        it { should_not respond_to("#{scope}_eq") }
        it { should respond_to("#{scope}_gt") }
        it { should respond_to("#{scope}_lt") }
        it { should_not respond_to("#{scope}_gte") }
        it { should_not respond_to("#{scope}_lte") }
      end
      it { should_not respond_to(:height) }
    end

    context "without arguments" do

      before { subject.float_scopes }

      it "defines all possible float scopes" do
        %w(rating floato floatum).each do |attr|
          should respond_to("#{attr}_gt")
        end
      end

      it "does not define float scopes with non float column types" do
        %w(moderator about created_at last_name age).each do |attr|
          should_not respond_to("#{attr}_gt")
        end
      end
    end

    describe "fetching" do
      before do
        [1.1, 2.2, 3.3].each { |val| User.create(rating: val) }
        subject.float_scopes(:rating)
      end

      it "returns 1 for lt" do
        subject.rating_lt(2).count.should == 1
      end

      it "returns 2 for gt" do
        subject.rating_gt(2).count.should == 2
      end
    end
  end
end