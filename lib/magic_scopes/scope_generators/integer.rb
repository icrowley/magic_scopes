module MagicScopes
  class IntegerScopesGenerator < ScopesGenerator::Base

    include EqualityScopes
    include OrderScopes
    include ComparisonScopes

    def gte
      scope "#{@attr}_gte", ->(val) { where("#{@key} >= ?", val) }
    end

    def lte
      scope "#{@attr}_lte", ->(val) { where("#{@key} <= ?", val) }
    end

  end

  # TODO
  # make something like:
  # %w(integer decimal time datetime date).each do |type|
  #   send("#{type.classify}=", NumScopesGenerator)
  # end
  DecimalScopesGenerator  = IntegerScopesGenerator
  TimeScopesGenerator     = IntegerScopesGenerator
  DatetimeScopesGenerator = IntegerScopesGenerator
  DateScopesGenerator     = IntegerScopesGenerator
end
