module MagicScopes
  module PresenceScopes
    def with(name)
      scope name || "with_#{@attr}", where("#{@key} IS NOT NULL")
    end

    def without(name)
      scope name || "without_#{@attr}", where("#{@key} IS NULL")
    end
  end
end
