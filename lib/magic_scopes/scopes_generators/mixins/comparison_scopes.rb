module MagicScopes
  module ComparisonScopes
    def gt(name)
      scope name || "#{@attr}_gt", ->(val){ where("#{@key} > ?", val) }
    end

    def lt(name)
      scope name || "#{@attr}_lt", ->(val){ where("#{@key} < ?", val) }
    end
  end
end
