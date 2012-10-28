module MagicScopes
  class StringScopesGenerator < ScopesGenerator::Base

    include EqualityScopes
    include OrderScopes

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
  end

  TextScopesGenerator = StringScopesGenerator
end
