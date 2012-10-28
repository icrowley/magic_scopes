require 'magic_scopes/standard_scopes'
require 'magic_scopes/scopes_builder'
require 'magic_scopes/scopes_generators/mixins/order_scopes'
require 'magic_scopes/scopes_generators/mixins/comparison_scopes'
require 'magic_scopes/scopes_generators/mixins/equality_scopes'
require 'magic_scopes/scopes_generators/mixins/presence_scopes'
require 'magic_scopes/scopes_generators/base'
require 'magic_scopes/scopes_generators/boolean'
require 'magic_scopes/scopes_generators/integer'
require 'magic_scopes/scopes_generators/string'
require 'magic_scopes/scopes_generators/float'
require 'magic_scopes/scopes_generators/association'
require 'magic_scopes/scopes_generators/state'
require 'magic_scopes/version'
require 'magic_scopes/railtie' if defined?(Rails)


module MagicScopes
  extend ActiveSupport::Concern

  module ClassMethods
    def magic_scopes(*attrs)
      builder = ScopesBuilder.new(self, *attrs)
      builder.generate_standard_scopes
      builder.generate_scopes
    end
  end
end
