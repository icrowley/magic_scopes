require 'spec_helper'

describe MagicScopes do
  describe ".string_scopes" do
    before { User.connection.execute('PRAGMA case_sensitive_like = 1;') } if User.connection.adapter_name == 'SQLite'
    subject { User }

    context "with arguments" do
      before { subject.string_scopes(:email, :about) }
      %w(email about).each do |scope|
        it { should respond_to("with_#{scope}") }
        it { should respond_to("without_#{scope}") }
        it { should respond_to("#{scope}_eq") }
        it { should respond_to("#{scope}_like") }
        it { should respond_to("#{scope}_ilike") }
        it { should respond_to("#{scope}_ne") }
        it { should respond_to("by_#{scope}") }
        it { should respond_to("by_#{scope}_desc") }
      end
      it { should_not respond_to(:height) }
    end

    context "without arguments" do

      before { subject.string_scopes }

      it "defines all possible string scopes" do
        %w(email about first_name last_name).each do |attr|
          should respond_to("with_#{attr}")
        end
      end

      it "does not define string scopes with non string column types" do
        %w(moderator created_at rating age height).each do |attr|
          should_not respond_to("with_#{attr}")
        end
      end

      it { should_not respond_to(:commentable_type_like) }
      it { should_not respond_to(:state_like) }
    end

    describe "fetching" do

      context "email" do
        before do
          User.create(email: 'test@example.org')
          User.create(email: 'bogus@example.org')
          subject.string_scopes(:email)
        end

        it "returns 1 for exact search" do
          subject.with_email('test@example.org').count.should == 1
        end

        it "returns 1 for eq" do
          subject.email_eq('test@example.org').count.should == 1
        end

        it "returns 2 for like" do
          subject.email_like('example.org').count.should == 2
        end
      end

      context "about" do
        before do
          User.create(about: 'Lorem Ipsum')
          User.create(about: 'lorem ipsum')
          subject.string_scopes(:about)
        end

        it "returns 1 for exact search" do
          subject.with_about('Lorem Ipsum').count.should == 1
        end

        it "accepts multiple arguments" do
          User.create(about: 'bogus')
          subject.with_about('bogus', 'lorem ipsum').count.should == 2
        end

        it "accepts multiple arguments for negative scope" do
          User.create(about: 'bogus')
          subject.about_ne('bogus', 'lorem ipsum').count.should == 1
        end

        it "returns 1 for like" do
          subject.about_like('lorem').count.should == 1
        end

        it "returns 2 for ilike" do
          subject.about_ilike('lorem').count.should == 2
        end

        it "returns 1 for ne" do
          subject.about_ne('Lorem Ipsum').count.should == 1
        end

        it "returns 1 for ne with array" do
          User.create(about: 'bogus')
          subject.about_ne(['Lorem Ipsum', 'bogus']).count.should == 1
        end

        context "accepts symbols as arguments" do
          before { User.create(about: 'bogus') }
          it { subject.about_eq(:bogus).count.should == 1 }
          it { subject.about_ne(:bogus).count.should == 2 }
        end

        describe "with/without" do
          before { User.create }

          it "returns 2 for with" do
            subject.with_about.count.should == 2
          end

          it "returns 1 for without" do
            subject.without_about.count.should == 1
          end
        end
      end
    end

    describe "by scopes" do
      before do
        %w(b c a).each { |l| User.create(about: l) }
        subject.string_scopes(:about)
      end

      it "properly sorts asc" do
        subject.by_about.map(&:about).should == %w(a b c)
      end

      it "properly sorts desc" do
        subject.by_about_desc.map(&:about).should == %w(c b a)
      end
    end
  end
end
