ENV['RAILS_ENV'] = 'test'

Bundler.require(:development)

require_relative 'dummy/config/environment.rb'

Dir[File.join(File.dirname(__FILE__), '/support/**/*.rb')].each { |f| require f }

