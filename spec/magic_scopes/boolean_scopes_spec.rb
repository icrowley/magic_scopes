require 'spec_helper'

describe MagicScopes do
  describe "boolean scopes" do
    subject { Comment }

    describe "generated scopes" do
      let(:attrs) { [:featured, :hidden, :best] }
      before { subject.magic_scopes(*attrs) }

      it "defines all possible boolean scopes" do
        attrs.each do |attr|
          should respond_to(attr)
          should respond_to("not_#{attr}")
          should respond_to("with_#{attr}")
          should respond_to("without_#{attr}")
        end
      end

      it "does not define boolean scopes with non boolean column types" do
        (subject.send(:all_possible_attrs) - attrs).each do |attr|
          should_not respond_to(attr)
          should_not respond_to("not_#{attr}")
          should_not respond_to("with_#{attr}")
          should_not respond_to("without_#{attr}")
        end
      end
    end

    describe "fetching" do
      before do
        subject.magic_scopes(:hidden)
        [true, false, nil].each { |val| subject.create(hidden: val) }
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
