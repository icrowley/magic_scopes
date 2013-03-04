module MagicScopes
  class BooleanScopesGenerator < ScopesGenerator::Base

    include PresenceScopes

    def is(name)
      scope name || @attr, -> { where("#{@key}" => true) }
    end

    def not(name)
      scope name || "not_#{@attr}", -> { where("#{@key}" => [false, nil]) }
    end
  end
end
