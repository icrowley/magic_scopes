require 'spec_helper'

describe MagicScopes do
  describe "string scopes" do
    subject { User }
    before { User.connection.execute('PRAGMA case_sensitive_like = 1;') } if User.connection.adapter_name == 'SQLite'

    describe "generated scopes" do
      let(:attrs) { [:email, :about, :first_name, :last_name] }
      before { subject.magic_scopes(*attrs) }

      it "defines all possible string scopes" do
        attrs.each do |attr|
          should respond_to("with_#{attr}")
          should respond_to("without_#{attr}")
          should respond_to("#{attr}_eq")
          should respond_to("#{attr}_like")
          should respond_to("#{attr}_ilike")
          should respond_to("#{attr}_ne")
          should respond_to("by_#{attr}")
          should respond_to("by_#{attr}_desc")
        end
      end

      it "does not define string scopes with non string column types" do
        (subject.send(:all_possible_attrs) - attrs).each do |attr|
          should_not respond_to("with_#{attr}")
          should_not respond_to("without_#{attr}")
          should_not respond_to("#{attr}_eq")
          should_not respond_to("#{attr}_like")
          should_not respond_to("#{attr}_ilike")
          should_not respond_to("#{attr}_ne")
          should_not respond_to("by_#{attr}")
          should_not respond_to("by_#{attr}_desc")
        end
      end
    end

    describe "fetching" do

      context "email" do
        before do
          subject.magic_scopes(:email)
          subject.create(email: 'test@example.org')
          subject.create(email: 'bogus@example.org')
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
          subject.magic_scopes(:about)
          subject.create(about: 'Lorem Ipsum')
          subject.create(about: 'lorem ipsum')
        end

        it "returns 1 for exact search" do
          subject.with_about('Lorem Ipsum').count.should == 1
        end

        it "accepts multiple arguments" do
          subject.create(about: 'bogus')
          subject.with_about('bogus', 'lorem ipsum').count.should == 2
        end

        it "accepts multiple arguments for negative scope" do
          subject.create(about: 'bogus')
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
          subject.create(about: 'bogus')
          subject.about_ne(['Lorem Ipsum', 'bogus']).count.should == 1
        end

        context "accepts symbols as arguments" do
          before { subject.create(about: 'bogus') }
          it { subject.about_eq(:bogus).count.should == 1 }
          it { subject.about_ne(:bogus).count.should == 2 }
        end

        describe "with/without" do
          before { subject.create }

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
        subject.magic_scopes(:about)
        %w(b c a).each { |l| subject.create(about: l) }
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
