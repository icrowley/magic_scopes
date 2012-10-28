module MagicScopes
  module EqualityScopes
    def with
      scope "with_#{@attr}", eq_scope
    end

    def eq
      scope "#{@attr}_eq", eq_scope
    end

    def without
      scope "without_#{@attr}", where("#{@key} IS NULL")
    end

    def ne
      scope "#{@attr}_ne", ->(*vals) {
        raise ArgumentError, "No argument for for_#{@attr} scope" if vals.empty?
        sql = "#{@key} " << (vals.size == 1 && !vals[0].is_a?(Array) ? '!= ?' : 'NOT IN (?)') << " OR #{@key} IS NULL"
        where(sql, vals.flatten)
      }
    end

    private

    def eq_scope
      @eq_scope ||= ->(*vals) { vals.empty? ? where("#{@key} IS NOT NULL") : where(@key => vals.flatten) }
    end

  end
end
