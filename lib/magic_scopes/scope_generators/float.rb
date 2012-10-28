module MagicScopes
  class FloatScopesGenerator < ScopesGenerator::Base
    def gt
      scope "#{@attr}_gt", ->(val){ where("#{@key} > ?", val) }
    end

    def lt
      scope "#{@attr}_lt", ->(val){ where("#{@key} < ?", val) }
    end

    def by
      scope "by_#{@attr}", order("#{@attr} ASC")
    end

    def by_desc
      scope "by_#{@attr}_desc", order("#{@attr} DESC")
    end

    def with
      scope "with_#{@attr}", where("#{@key} IS NOT NULL")
    end

    def without
      scope "without_#{@attr}", where("#{@key} IS NULL")
    end
  end
end
