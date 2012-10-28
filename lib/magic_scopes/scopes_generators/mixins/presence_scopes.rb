module MagicScopes
  module PresenceScopes
    def with
      scope "with_#{@attr}", where("#{@key} IS NOT NULL")
    end

    def without
      scope "without_#{@attr}", where("#{@key} IS NULL")
    end
  end
end
