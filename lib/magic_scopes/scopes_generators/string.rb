module MagicScopes
  class StringScopesGenerator < ScopesGenerator::Base

    include EqualityScopes
    include OrderScopes

    def like(name)
      scope name || "#{@attr}_like", ->(*vals) { where(build_query(*vals, "#{@key} LIKE ?", 'OR')) }
    end

    def not_like(name)
      scope name || "#{@attr}_not_like", ->(*vals) { where(build_query(*vals, "#{@key} NOT LIKE ?", 'AND')) }
    end

    def ilike(name)
      scope name || "#{@attr}_ilike", ilike_scope
    end

    def not_ilike(name)
      scope name || "#{@attr}_not_ilike", ilike_scope('NOT')
    end

    private

    def build_query(*vals, condition, operator)
      [Array.new(vals.size, condition).join(" #{operator} "), *vals.map { |val| "%#{val}%" }]
    end

    def ilike_scope(operator = nil)
      conditions = ilike_supported? ? "#{@key} #{operator} ILIKE ?" : "LOWER(#{@key}) #{operator} LIKE ?"
      ->(*vals){ where(build_query(*vals, conditions, operator != 'NOT' ? 'OR' : 'AND')) }
    end

    def ilike_supported?
      @model.connection.adapter_name == 'PostgreSQL'
    end
  end

  TextScopesGenerator = StringScopesGenerator
end
