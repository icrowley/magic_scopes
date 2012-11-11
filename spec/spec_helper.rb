ENV["RAILS_ENV"] ||= 'test'
require_relative 'dummy/config/environment'

require 'rspec/rails'

class ActiveRecord::Base
  def self.undef_meth(name)
    (class << self; self; end).instance_eval { remove_method(name) }
  end
end


RSpec.configure do |config|
  config.use_transactional_fixtures = true

  config.after(:each) do
    [User, Comment].each do |model|
      MagicScopes::ScopesBuilder.new(model).send(:all_possible_attributes).each do |arg|
        model.undef_meth(arg) if model.respond_to?(arg)
        %w(eq gt lt gte lte ne like not_like ilike not_ilike).each do |postfix|
          m = "#{arg}_#{postfix}"
          model.undef_meth(m) if model.respond_to?(m)
        end
        %w(with without by not for not_for).each do |prefix|
          m = "#{prefix}_#{arg}"
          model.undef_meth(m) if model.respond_to?(m) && !%w(with_state with_likes_state).include?(m)
        end
        m = "by_#{arg}_desc"
        model.undef_meth(m) if model.respond_to?(m)
        MagicScopes::ScopesBuilder::STANDARD_SCOPES.each { |m| model.undef_meth(m) if model.respond_to?(m) }
      end
    end
  end
end
