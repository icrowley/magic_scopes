require 'magic_scopes/version'
require 'magic_scopes/railtie' if defined?(Rails)

module MagicScopes

  class WrongTypeError < StandardError; end
  class NoAssociationError < StandardError; end
  class NoStateMachineError < StandardError; end

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

    def string_scopes(*attrs)
      define_scopes([:string, :text], attrs) do |attr|
        scope "with_#{attr}",  ->(val) { where("#{table_name}.#{attr}" => val) }
        scope "#{attr}_eq",    ->(val) { where("#{table_name}.#{attr}" => val) }
        scope "#{attr}_ne",    ->(val) {
          sql = "#{table_name}.#{attr} " << (val.is_a?(Array) ? 'NOT IN (?)' : '!= ?') << " OR #{table_name}.#{attr} IS NULL"
          where(sql, val)
        }
        scope "#{attr}_like",  ->(val) { where("#{table_name}.#{attr} LIKE ?", "%#{val}%") }

        ilike_scope = if connection.adapter_name == 'PostgreSQL'
          ->(val){ where("#{table_name}.#{attr} ILIKE ?", "%#{val}%") }
        else
          ->(val){ where("LOWER(#{table_name}.#{attr}) LIKE ?", "%#{val}%") }
        end
        scope "#{attr}_ilike", ilike_scope
      end
    end

    def assoc_scopes(*attrs)
      def parse_attrs(val)
        if val.is_a?(Fixnum) || val.is_a?(String)
          val
        elsif val.is_a?(ActiveRecord::Base)
          val.id
        elsif val.is_a?(Array) && val.all? { |v| v.is_a?(Fixnum) }
          val
        elsif val.is_a?(Array) && val.all? { |v| v.is_a?(ActiveRecord::Base) }
          val.map(&:id)
        else
          raise ArgumentError, "Wrong argument type #{attr.class.name} for argument #{attr}"
        end
      end

      def parse_options(attr, operator, *vals)
        vals.inject([]) do |conditions, val|
          parsed_attrs = parse_attrs(val)
          conditions << if parsed_attrs.is_a?(String)
            "#{table_name}.#{attr}_type #{operator} '#{parsed_attrs}'"
          elsif parsed_attrs.is_a?(Fixnum)
            build_fk_conditions(attr, operator) { |key| "#{key} #{operator} #{parsed_attrs}" }
          else
            build_fk_conditions(attr, operator) { |key| "#{key} #{'NOT' if operator == '!='} IN (#{parsed_attrs.join(', ')})" }
          end
        end.join(' AND ')
      end

      def build_fk_conditions(attr, operator, &block)
        key = "#{table_name}.#{attr.to_s.foreign_key}"
        fk = yield(key)
        operator == '!=' ? ("#{fk} OR #{key} IS NULL") : fk
      end

      attrs = reflections.keys if attrs.empty?
      attrs.each do |attr|
        if reflection = reflections[attr.to_sym]
          if reflection.options[:polymorphic]
            scope "for_#{attr}",     ->(*vals) { where(parse_options(attr, '=', *vals)) }
            scope "not_for_#{attr}", ->(*vals) { where(parse_options(attr, '!=', *vals)) }
          else
            scope "for_#{attr}",     ->(val) { where("#{table_name}.#{attr.to_s.foreign_key}" => parse_attrs(val)) }
            scope "not_for_#{attr}", ->(val) {
              parsed_attrs = parse_attrs(val)
              conditions = if parsed_attrs.is_a?(Array)
                "NOT IN (#{parsed_attrs.join(', ')})"
              else
                "!= #{parsed_attrs}"
              end
              key = "#{table_name}.#{attr.to_s.foreign_key}"
              where("#{key} #{conditions} OR #{key} IS NULL")
            }
          end
        else
          raise NoAssociationError, "No association for attribute #{attr}"
        end
      end
    end

    if defined?(StateMachine)
      def state_scopes(*attrs)
        attrs = state_machines.keys if attrs.empty?
        attrs.each do |attr|
          if sm = state_machines[attr]
            sm.states.map(&:name).each do |state|
              state = "no_#{attr}" if state.nil?
              scope state,          where("#{table_name}.#{attr}" => state)
              scope "not_#{state}", where("#{table_name}.#{attr} != ? OR #{table_name}.#{attr} IS NULL", state)
            end
          else
            raise NoStateMachineError, "No state machine for attribute #{attr}"
          end
        end
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
        scope "with_#{attr}", ->(val) { where("#{table_name}.#{attr}" => val) }
        scope "#{attr}_eq",   ->(val) { where("#{table_name}.#{attr}" => val) }
        scope "#{attr}_gt",   ->(val) { where("#{table_name}.#{attr} > ?", val) }
        scope "#{attr}_lt",   ->(val) { where("#{table_name}.#{attr} < ?", val) }
        scope "#{attr}_gte",  ->(val) { where("#{table_name}.#{attr} >= ?", val) }
        scope "#{attr}_lte",  ->(val) { where("#{table_name}.#{attr} <= ?", val) }
        scope "#{attr}_ne",   ->(val) {
          sql = "#{table_name}.#{attr} " << (val.is_a?(Array) ? "NOT IN (?)" : "!= ?") << " OR #{table_name}.#{attr} IS NULL"
          where(sql, val)
        }
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
