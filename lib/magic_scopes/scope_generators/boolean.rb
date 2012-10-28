module MagicScopes
  class BooleanScopesGenerator < ScopesGenerator::Base
    def is
      scope @attr, where("#{@key}" => true)
    end

    def not
      scope "not_#{@attr}", where("#{@key}" => [false, nil])
    end

    def with
      scope "with_#{@attr}", where("#{@key} IS NOT NULL")
    end

    def without
      scope "without_#{@attr}", where("#{@key} IS NULL")
    end
  end
end
