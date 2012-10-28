require 'spec_helper'

describe MagicScopes do
  describe "float scopes" do
    subject { User }

    describe "generated scopes" do
      let(:attrs) { [:rating, :floato, :floatum] }
      before { subject.magic_scopes(*attrs) }

      it "defines all possible float scopes" do
        attrs.each do |attr|
          should_not respond_to(attr)
          should_not respond_to("#{attr}_eq")
          should respond_to("with_#{attr}")
          should respond_to("without_#{attr}")
          should respond_to("#{attr}_gt")
          should respond_to("#{attr}_lt")
          should respond_to("by_#{attr}")
          should respond_to("by_#{attr}_desc")
          should_not respond_to("#{attr}_gte")
          should_not respond_to("#{attr}_lte")
        end
      end

      it "does not define float scopes with non float column types" do
        (subject.send(:attrs_list) - attrs).each do |attr|
          should_not respond_to("with_#{attr}")
          should_not respond_to("without_#{attr}")
          should_not respond_to("#{attr}_gt")
          should_not respond_to("#{attr}_lt")
          should_not respond_to("by_#{attr}")
          should_not respond_to("by_#{attr}_desc")
        end
      end
    end

    describe "fetching" do
      before do
        subject.magic_scopes(:rating)
        [2.2, 1.1, 3.3].each { |val| subject.create(rating: val) }
      end

      it "returns 1 for lt" do
        subject.rating_lt(2).count.should == 1
      end

      it "returns 2 for gt" do
        subject.rating_gt(2).count.should == 2
      end

      describe "by scopes" do
        it "properly sorts asc" do
          subject.by_rating.map(&:rating).should == [1.1, 2.2, 3.3]
        end

        it "properly sorts desc" do
          subject.by_rating_desc.map(&:rating).should == [3.3, 2.2, 1.1]
        end
      end

      describe "with/without" do
        before { subject.create }

        it "returns 3 for with" do
          subject.with_rating.count.should == 3
        end

        it "returns 1 for without" do
          subject.without_rating.count.should == 1
        end
      end
    end

  end
end
