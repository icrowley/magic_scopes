require 'spec_helper'

describe MagicScopes do

  describe "ActiveRecord::Base methods" do
    subject { ActiveRecord::Base }

    it { should respond_to(:magic_scopes) }
  end

  describe ".magic_scopes" do
    subject { Comment }

    context "without arguments" do
      before { subject.magic_scopes }

      it { should respond_to(:title_like) }
      it { should respond_to(:content_like) }

      %w(user next).each do |attr|
        it { should respond_to("for_#{attr}") }
        it { should respond_to("with_#{attr}_id") }
      end
      it { should respond_to(:for_commentable) }
      it { should respond_to(:with_commentable_id) }
      it { should respond_to(:with_commentable_type) }

      %w(pending accepted refused liked disliked featured hidden best).each do |attr|
        it { should respond_to("not_#{attr}") }
      end
      it { should_not respond_to(:state_like) }
      it { should_not respond_to(:likes_state_like) }

      it { should respond_to(:likes_num_gte) }
      it { should respond_to(:created_at_gte) }
      it { should respond_to(:rating_gt) }
      it { should_not respond_to(:rating_gte) }
    end

    it "raises error if non existed attr passed" do
      expect { subject.magic_scopes :title, :bogus }.to raise_error(ActiveRecord::UnknownAttributeError)
    end

    it "does not raise error if all attrs are exist" do
      expect { subject.magic_scopes :title, :rating }.to_not raise_error
    end

    describe "options" do
      it "uses all types of scopes unless in/ex options specified" do
        subject.magic_scopes.keys.should == subject.send(:attrs_list)
      end

      it "accepts arrays as arguments to options as well as symbols and strings" do
        expect { subject.magic_scopes in: %w(eq ne) }.to_not raise_error
        expect { subject.magic_scopes in: :eq }.to_not raise_error
        expect { subject.magic_scopes in: 'eq' }.to_not raise_error
      end

      it "raises error if both in and ex options are specified" do
        expect { subject.magic_scopes in: %w(eq ne), ex: :with }.to raise_error(ArgumentError)
      end


      describe "standard" do
        context "without arguments" do
          before { subject.magic_scopes }

          it "responds to all standard scopes" do
            subject::STANDARD_SCOPES.each do |scope|
              should respond_to(scope)
            end
          end
        end

        context "with arguments" do
          let(:scopes) { %w(sorted recent) }
          before { subject.magic_scopes(std: scopes) }

          it "responds only to to specified standard scopes" do
            scopes.each { |scope| should respond_to(scope) }
          end

          it "does not respond to not specified standard scopes" do
            (subject::STANDARD_SCOPES - scopes.map(&:to_sym)).each { |scope| should_not respond_to(scope) }
          end
        end

        context "with wrong options passed" do
          it "raises argument error" do
            expect { subject.magic_scopes(std: %w(recent bogus)) }.to raise_error(ArgumentError)
          end
        end
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

        it "does not raise error if scopes for all attrs can be built" do
          expect { subject.magic_scopes :title, in: %w(eq ne) }.to_not raise_error
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

        it "does not raise error if scopes for all attrs can be built" do
          expect { subject.magic_scopes :title, ex: %w(for not_for is not gt gte lt lte) }.to_not raise_error
        end

        it "does not raise error if scopes can not be built if no attributes passed" do
          expect { subject.magic_scopes ex: %w(eq ne) }.to_not raise_error
        end
      end

      describe "generating scopes" do
        context "with include option specified`" do
          before { subject.magic_scopes(:title, :likes_num, in: %w(eq ne)) }
          it "generates all needed scopes" do
            %w(title_eq title_ne likes_num_eq likes_num_ne).each { |scope| should respond_to(scope) }
          end
        end

        context "witn empty include option" do
          before { subject.magic_scopes(:title, :likes_num, in: []) }
          it "does not generate any scopes except standard ones" do
            subject::STANDARD_SCOPES.each { |scope| should respond_to(scope) }
            %w(title_eq title_ne likes_num_eq likes_num_ne).each { |scope| should_not respond_to(scope) }
          end
        end
      end
    end

  end
end
