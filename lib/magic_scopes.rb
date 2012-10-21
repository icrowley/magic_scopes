require 'magic_scopes/version'
require 'magic_scopes/railtie' if defined?(Rails)

module MagicScopes

  class WrongTypeError < StandardError; end;

  extend ActiveSupport::Concern

  module ClassMethods

    def boolean_scopes(*attrs)
      define_scopes(:boolean, attrs) do |attr|
        scope attr,          where("#{table_name}.#{attr}" => true)
        scope "not_#{attr}", where("#{table_name}.#{attr}" => [false, nil])
      end
    end

    def num_scopes(*attrs)
      num_time_scopes([:integer, :decimal], attrs)
    end

    def time_scopes(*attrs)
      num_time_scopes([:time, :datetime, :date], attrs)
    end

    def float_scopes(*attrs)
      define_scopes(:float, attrs) do |attr|
        scope "#{attr}_gt", ->(val){ where("#{table_name}.#{attr} > ?", val) }
        scope "#{attr}_lt", ->(val){ where("#{table_name}.#{attr} < ?", val) }
      end
    end

    if defined?(StateMachine)
      def state_scopes
        1
      end
    end

    def assoc_scopes

    end

    def string_scopes(*attrs)
      define_scopes([:string, :text], attrs) do |attr|
        scope "with_#{attr}",  ->(val){ where("#{table_name}.#{attr}" => val) }
        scope "#{attr}_eq",    ->(val){ where("#{table_name}.#{attr}" => val) }
        scope "#{attr}_like",  ->(val){ where("#{table_name}.#{attr} LIKE ?", "%#{val}%") }
        ilike_scope = if connection.adapter_name == 'PostgreSQL'
            ->(val){ where("#{table_name}.#{attr} ILIKE ?", "%#{val}%") }
          else
            ->(val){ where("LOWER(#{table_name}.#{attr}) LIKE ?", "%#{val}%") }
          end
        scope "#{attr}_ilike", ilike_scope
      end
    end

    def magic_scopes
      boolean_scopes
      num_scopes
      time_scopes
      float_scopes
      string_scopes
    end

    private

    def num_time_scopes(types, attrs)
      define_scopes(types, attrs) do |attr|
        scope "with_#{attr}", ->(val){ where("#{table_name}.#{attr}" => val) }
        scope "#{attr}_eq",   ->(val){ where("#{table_name}.#{attr}" => val) }
        scope "#{attr}_gt",   ->(val){ where("#{table_name}.#{attr} > ?", val)  }
        scope "#{attr}_lt",   ->(val){ where("#{table_name}.#{attr} < ?", val)  }
        scope "#{attr}_gte",  ->(val){ where("#{table_name}.#{attr} >= ?", val) }
        scope "#{attr}_lte",  ->(val){ where("#{table_name}.#{attr} <= ?", val) }
      end
    end

    def define_scopes(types, attrs, &block)
      types = Array.wrap(types)
      attrs = columns_hash.inject([]) { |ar, (attr, meta)| ar << attr if meta.type.in?(types); ar } if attrs.empty?
      attrs.each do |attr|
        begin
          if (type = columns_hash[attr.to_s].type).in?(types)
            yield(attr)
          else
            raise WrongTypeError, "Wrong type #{type} for argument #{attr}"
          end
        rescue NoMethodError
          raise ActiveRecord::UnknownAttributeError, "Unknown attribute: #{attr}"
        end
      end
    end
  end
end
