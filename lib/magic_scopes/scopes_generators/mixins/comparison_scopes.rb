module MagicScopes
  module ComparisonScopes
    def gt
      scope "#{@attr}_gt", ->(val){ where("#{@key} > ?", val) }
    end

    def lt
      scope "#{@attr}_lt", ->(val){ where("#{@key} < ?", val) }
    end
  end
end
