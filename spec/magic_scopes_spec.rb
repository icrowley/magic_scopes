require 'spec_helper'

describe MagicScopes do
  subject { Comment }

  it "raises error if non existed attr passed" do
    expect { subject.magic_scopes :title, :bogus }.to raise_error(ActiveRecord::UnknownAttributeError)
  end

  it "does not raise error if all attrs are exist" do
    expect { subject.magic_scopes :title, :rating }.to_not raise_error
  end

  describe "options" do
    it "uses all types of scopes unless in/ex options specified" do
      subject.magic_scopes.should == subject.send(:attrs_list)
    end

    it "accepts arrays as arguments to options as well as symbols and strings" do
      expect { subject.magic_scopes in: %w(eq ne) }.to_not raise_error
      expect { subject.magic_scopes in: :eq }.to_not raise_error
      expect { subject.magic_scopes in: 'eq' }.to_not raise_error
    end

    it "raises error if both in and ex options are specified" do
      expect { subject.magic_scopes in: %w(eq ne), ex: :with }.to raise_error(ArgumentError)
    end

    describe "include" do
      it "does not raise error if all options are allowed ones" do
        expect { subject.magic_scopes in: %w(eq ne) }.to_not raise_error
      end

      it "raises error if any of the options do not exist" do
        expect { subject.magic_scopes in: %w(eq ne bogus) }.to raise_error(ArgumentError)
      end

      it "raises error if there is attr for which scope can not be built with passed options" do
        expect { subject.magic_scopes :title, :rating, in: %w(eq ne) }.to raise_error(ArgumentError)
      end

      it "does not raise error if scopes can not be built if no attributes passed" do
        expect { subject.magic_scopes in: %w(eq ne) }.to_not raise_error
      end
    end

    describe "exclude" do
      it "does not raise error if all options are allowed ones" do
        expect { subject.magic_scopes ex: %w(eq ne) }.to_not raise_error
      end

      it "raises error if any of the options do not exist" do
        expect { subject.magic_scopes ex: %w(eq ne bogus) }.to raise_error(ArgumentError)
      end

      it "raises error if there is attr for which scope can not be built with passed options" do
        expect { subject.magic_scopes :title, :rating, ex: %w(eq ne) }.to raise_error(ArgumentError)
      end

      it "does not raise error if scopes can not be built if no attributes passed" do
        expect { subject.magic_scopes ex: %w(eq ne) }.to_not raise_error
      end
    end
  end
end
