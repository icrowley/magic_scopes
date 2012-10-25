ENV["RAILS_ENV"] ||= 'test'
require_relative 'dummy/config/environment'

require 'rspec/rails'

class ActiveRecord::Base
  def self.undef_scope(name)
    (class << self; self; end).instance_eval { remove_method(name) }
  end
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true

  config.after(:all) do
    [User, Comment].each do |model|
      states = model.state_machines.keys.inject([]) do |ar, sm_key|
        ar += model.state_machines[sm_key].states.map(&:name).map { |el| el || "nil_#{sm_key}" }
        ar
      end

      (model.columns_hash.keys + model.reflections.keys + states).each do |arg|
        model.undef_scope(arg) if model.respond_to?(arg)
        %w(eq gt lt gte lte ne like ilike).each do |postfix|
          m = "#{arg}_#{postfix}"
          model.undef_scope(m) if model.respond_to?(m)
        end
        %w(with not for not_for).each do |prefix|
          m = "#{prefix}_#{arg}"
          model.undef_scope(m) if model.respond_to?(m) && !m.in?(%(with_state with_likes_state))
        end
      end
    end
  end
end