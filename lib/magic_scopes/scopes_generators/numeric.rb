module MagicScopes
  class NumericScopesGenerator < ScopesGenerator::Base

    include EqualityScopes
    include OrderScopes
    include ComparisonScopes

    def gte(name)
      scope name || "#{@attr}_gte", ->(val) { where("#{@key} >= ?", val) }
    end

    def lte(name)
      scope name || "#{@attr}_lte", ->(val) { where("#{@key} <= ?", val) }
    end

  end
end
