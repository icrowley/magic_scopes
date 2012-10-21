require 'spec_helper'

describe MagicScopes do
  describe ".time_scopes" do
    subject { User }

    context "with arguments" do
      before { subject.time_scopes(:created_at, :updated_at) }
      %w(created_at updated_at).each do |scope|
        it { should respond_to("with_#{scope}") }
        it { should respond_to("#{scope}_eq") }
        it { should respond_to("#{scope}_gt") }
        it { should respond_to("#{scope}_lt") }
        it { should respond_to("#{scope}_gte") }
        it { should respond_to("#{scope}_lte") }
      end
      it { should_not respond_to(:last_logged_at) }
    end

    context "without arguments" do

      before do
        subject.time_scopes
      end

      it "defines all possible time scopes" do
        %w(created_at updated_at last_logged_at).each do |attr|
          should respond_to("with_#{attr}")
        end
      end

      it "does not define time scopes with non time column types" do
        %w(moderator about hidden height last_name rating).each do |attr|
          should_not respond_to("with_#{attr}")
        end
      end
    end

    describe "fetching" do
      let(:today) { Date.today.to_time }
      before do
        (-1..2).each { |val| User.create(last_logged_at: today + val.days) }
        subject.time_scopes(:last_logged_at)
      end

      it "returns 1 for last_logged_at" do
        subject.with_last_logged_at(today).count.should == 1
      end

      it "returns 1 for eq" do
        subject.last_logged_at_eq(today).count.should == 1
      end

      it "returns 1 for lt" do
        subject.last_logged_at_lt(today).count.should == 1
      end

      it "returns 2 for lte" do
        subject.last_logged_at_lte(today).count.should == 2
      end

      it "returns 2 for gt" do
        subject.last_logged_at_gt(today).count.should == 2
      end

      it "returns 3 for gte" do
        subject.last_logged_at_gte(today).count.should == 3
      end
    end
  end
end