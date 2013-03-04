module MagicScopes
  module OrderScopes
    def by(name)
      scope name || "by_#{@attr}", -> { order("#{@attr} ASC") }
    end

    def by_desc(name)
      scope name || "by_#{@attr}_desc", -> { order("#{@attr} DESC") }
    end
  end
end
