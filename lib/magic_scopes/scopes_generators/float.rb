module MagicScopes
  class FloatScopesGenerator < ScopesGenerator::Base
    include OrderScopes
    include ComparisonScopes
    include PresenceScopes
  end
end
