require 'spec_helper'

describe MagicScopes do

  describe "ActiveRecord::Base methods" do
    subject { ActiveRecord::Base }

    %w(boolean_scopes state_scopes assoc_scopes num_scopes time_scopes string_scopes magic_scopes).each do |scope_method|
      it { should respond_to(scope_method) }
    end
  end

  describe ".define_scopes" do
    subject { Comment }

    it "raises an error when argument is not of needed type" do
      expect { subject.boolean_scopes(:state) }.to raise_error(MagicScopes::WrongTypeError)
    end

    it "raises an error when argument is not a column" do
      expect { subject.boolean_scopes(:bogus) }.to raise_error(ActiveRecord::UnknownAttributeError)
    end
  end

end