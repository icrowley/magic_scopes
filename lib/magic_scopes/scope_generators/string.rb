module MagicScopes
  class StringScopesGenerator < ScopesGenerator::Base

    def with
      scope "with_#{@attr}", eq_scope
    end

    def eq
      scope "#{@attr}_eq", eq_scope
    end

    def eq_scope
      @eq_scope ||= ->(*vals) { vals.empty? ? where("#{@key} IS NOT NULL") : where(@key => vals.flatten) }
    end
    private :eq_scope

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

    def like
      scope "#{@attr}_like", ->(val) { where("#{@key} LIKE ?", "%#{val}%") }
    end

    def ilike
      ilike_scope = if @model.connection.adapter_name == 'PostgreSQL'
        ->(val){ where("#{@key} ILIKE ?", "%#{val}%") }
      else
        ->(val){ where("LOWER(#{@key}) LIKE ?", "%#{val}%") }
      end
      scope "#{@attr}_ilike", ilike_scope
    end

    def by
      scope "by_#{@attr}", order("#{@attr} ASC")
    end

    def by_desc
      scope "by_#{@attr}_desc", order("#{@attr} DESC")
    end
  end

  TextScopesGenerator = StringScopesGenerator
end
