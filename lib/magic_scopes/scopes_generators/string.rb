module MagicScopes
  class StringScopesGenerator < ScopesGenerator::Base

    include EqualityScopes
    include OrderScopes

    def like
      scope "#{@attr}_like", ->(*vals) { where(build_query(*vals, "#{@key} LIKE ?")) }
    end

    def ilike
      ilike_scope = if @model.connection.adapter_name == 'PostgreSQL'
        ->(*vals){ where(build_query(*vals, "#{@key} ILIKE ?")) }
      else
        ->(*vals){ where(build_query(*vals, "LOWER(#{@key}) LIKE ?")) }
      end
      scope "#{@attr}_ilike", ilike_scope
    end

    private

    def build_query(*vals, condition)
      [Array.new(vals.size, condition).join(' OR '), *vals.map { |val| "%#{val}%" }]
    end
  end

  TextScopesGenerator = StringScopesGenerator
end
