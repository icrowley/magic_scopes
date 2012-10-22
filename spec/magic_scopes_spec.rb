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
      expect { subject.boolean_scopes(:state) }.to raise_error(ArgumentError)
    end

    it "raises an error when argument is not a column" do
      expect { subject.boolean_scopes(:bogus) }.to raise_error(ActiveRecord::UnknownAttributeError)
    end
  end

  describe ".magic_scopes" do
    subject { Comment }

    context "without arguments" do
      before { subject.magic_scopes }

      it { should respond_to(:title_like) }
      it { should respond_to(:content_like) }

      %w(user next).each do |attr|
        it { should respond_to("for_#{attr}") }
        it { should_not respond_to("with_#{attr}_id") }
      end
      it { should respond_to(:for_commentable) }
      it { should_not respond_to(:with_commentable_id) }
      it { should_not respond_to(:with_commentable_type) }

      %w(pending accepted refused liked disliked nil_likes_state featured hidden best).each do |attr|
        it { should respond_to("not_#{attr}") }
      end
      it { should_not respond_to(:state_like) }
      it { should_not respond_to(:likes_state_like) }

      it { should respond_to(:likes_num_gte) }
      it { should respond_to(:created_at_gte) }
      it { should respond_to(:rating_gt) }
      it { should_not respond_to(:rating_gte) }
    end
  end

end