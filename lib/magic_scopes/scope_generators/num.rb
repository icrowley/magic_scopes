module MagicScopes
  class NumScopesGenerator < ScopesGenerator::Base
    def with
      scope "with_#{@attr}", ->(*vals) { vals.empty? ? where("#{@key} IS NOT NULL") : where(@key => vals.flatten) }
    end

    def without
      scope "without_#{@attr}", where("#{@key} IS NULL")
    end

    def eq
      scope "#{@attr}_eq", ->(val) { where(@key => val) }
    end

    def ne
      scope "#{@attr}_ne", ->(*vals) {
        raise ArgumentError, "No argument for for_#{@attr} scope" if vals.empty?
        sql = "#{@key} " << (vals.size == 1 && !vals[0].is_a?(Array) ? "!= ?" : "NOT IN (?)") << " OR #{@key} IS NULL"
        where(sql, vals.flatten)
      }
    end

    def gt
      scope "#{@attr}_gt", ->(val) { where("#{@key} > ?", val) }
    end

    def gte
      scope "#{@attr}_gte", ->(val) { where("#{@key} >= ?", val) }
    end

    def lt
      scope "#{@attr}_lt", ->(val) { where("#{@key} < ?", val) }
    end

    def lte
      scope "#{@attr}_lte", ->(val) { where("#{@key} <= ?", val) }
    end

    def by
      scope "by_#{@attr}", order("#{@key} ASC")
    end

    def by_desc
      scope "by_#{@attr}_desc", order("#{@key} DESC")
    end

  end

  # TODO
  # %w(integer decimal time datetime date).each do |type|
  #   send("#{type.classify}=", NumScopesGenerator)
  # end
  IntegerScopesGenerator  = NumScopesGenerator
  DecimalScopesGenerator  = NumScopesGenerator
  TimeScopesGenerator     = NumScopesGenerator
  DatetimeScopesGenerator = NumScopesGenerator
  DateScopesGenerator     = NumScopesGenerator
end
