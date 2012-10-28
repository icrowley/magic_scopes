module MagicScopes
  module OrderScopes
    def by
      scope "by_#{@attr}", order("#{@attr} ASC")
    end

    def by_desc
      scope "by_#{@attr}_desc", order("#{@attr} DESC")
    end
  end
end
