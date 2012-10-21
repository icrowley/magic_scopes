$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem"s version:
require "magic_scopes/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "magic_scopes"
  s.version     = MagicScopes::VERSION
  s.authors     = ["Some scopes generators"]
  s.email       = ["dimarzio1986@gmail.com"]
  s.homepage    = "https://github.com/icrowley"
  description   = "Some scopes generators"
  s.summary     = description
  s.description = description

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "activerecord", "~> 3.2"
  s.add_dependency "activesupport", "~> 3.2"

  s.add_development_dependency "rails", "~> 3.2"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "state_machine"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "pry-debugger"
end
