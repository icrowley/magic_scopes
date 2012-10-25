require 'spec_helper'

describe MagicScopes do
  describe ".boolean_scopes" do
    subject { Comment }

    context "with arguments" do

      before { subject.boolean_scopes(:featured, :hidden) }

      %w(featured hidden).each do |scope|
        it { should respond_to(scope) }
        it { should respond_to("not_#{scope}") }
        it { should respond_to("with_#{scope}") }
        it { should respond_to("without_#{scope}") }
      end
      it { should_not respond_to(:best) }
    end

    context "without args" do
      before { subject.boolean_scopes }

      it "defines all possible boolean scopes" do
        %w(featured hidden best).each do |attr|
          should respond_to(attr)
          should respond_to("not_#{attr}")
        end
      end

      it "does not define boolean scopes with non boolean column types" do
        %w(title conttent user_id state commentable_type created_at).each do |attr|
          should_not respond_to(attr)
          should_not respond_to("not_#{attr}")
        end
      end
    end

    describe "fetching" do
      before do
        [true, false, nil].each { |val| Comment.create(hidden: val) }
      end

      it "returns 1 for hidden" do
        subject.hidden.count.should == 1
      end

      it "returns 2 for non hidden" do
        subject.not_hidden.count.should == 2
      end

      it "returns 2 for with" do
        subject.with_hidden.count.should == 2
      end

      it "returns 1 for without" do
        subject.without_hidden.count.should == 1
      end
    end
  end
end
