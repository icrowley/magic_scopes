module MagicScopes
  class BooleanScopesGenerator < ScopesGenerator::Base

    include PresenceScopes

    def is
      scope @attr, where("#{@key}" => true)
    end

    def not
      scope "not_#{@attr}", where("#{@key}" => [false, nil])
    end
  end
end
