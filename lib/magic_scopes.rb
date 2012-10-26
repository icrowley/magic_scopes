require 'magic_scopes/version'
require 'magic_scopes/railtie' if defined?(Rails)

# interface:
# magic_scopes *attrs
# magic_scopes :rating, :age, :first_name, :last_name, in: %w(gt lt ne), std: %w(desc random)

module MagicScopes

  class WrongTypeError < StandardError; end
  class NoAssociationError < StandardError; end
  class NoStateMachineError < StandardError; end

  extend ActiveSupport::Concern

  module ClassMethods

    def asc_scope
      scope :asc, order(:id)
    end

    def desc_scope
      scope :desc,   order('id DESC')
      scope :recent, order('id DESC')
    end
    alias :recent_scope :desc_scope

    def random_scope
      scope :random, order('RANDOM()')
    end

    def standard_scopes
      asc_scope
      desc_scope
      random_scope
    end

    def boolean_scopes(*attrs)
      define_scopes(:boolean, attrs) do |attr|
        key = "#{table_name}.#{attr}"
        scope attr,              where("#{key}" => true)
        scope "not_#{attr}",     where("#{key}" => [false, nil])
        scope "with_#{attr}",    where("#{key} IS NOT NULL")
        scope "without_#{attr}", where("#{key} IS NULL")
      end
    end

    def num_scopes(*attrs)
      num_time_scopes([:integer, :decimal], attrs)
    end

    def time_scopes(*attrs)
      num_time_scopes([:time, :datetime, :date], attrs)
    end

    def num_time_scopes(types, attrs)
      define_scopes(types, attrs) do |attr|
        key = "#{table_name}.#{attr}"
        scope "with_#{attr}", ->(*vals) { vals.empty? ? where("#{key} IS NOT NULL") : where(key => vals.flatten) }
        scope "without_#{attr}", where("#{key} IS NULL")
        scope "#{attr}_eq",   ->(val) { where(key => val) }
        scope "#{attr}_gt",   ->(val) { where("#{key} > ?", val) }
        scope "#{attr}_lt",   ->(val) { where("#{key} < ?", val) }
        scope "#{attr}_gte",  ->(val) { where("#{key} >= ?", val) }
        scope "#{attr}_lte",  ->(val) { where("#{key} <= ?", val) }
        scope "#{attr}_ne",   ->(*vals) {
          raise ArgumentError, "No argument for for_#{attr} scope" if vals.empty?
          sql = "#{key} " << (vals.size == 1 && !vals[0].is_a?(Array) ? "!= ?" : "NOT IN (?)") << " OR #{key} IS NULL"
          where(sql, vals.flatten)
        }
        scope "by_#{attr}",      order("#{key} ASC")
        scope "by_#{attr}_desc", order("#{key} DESC")
      end
    end
    private :num_time_scopes

    def float_scopes(*attrs)
      define_scopes(:float, attrs) do |attr|
        key = "#{table_name}.#{attr}"
        scope "#{attr}_gt", ->(val){ where("#{key} > ?", val) }
        scope "#{attr}_lt", ->(val){ where("#{key} < ?", val) }
        scope "by_#{attr}",      order("#{attr} ASC")
        scope "by_#{attr}_desc", order("#{attr} DESC")
        scope "with_#{attr}",    where("#{key} IS NOT NULL")
        scope "without_#{attr}", where("#{key} IS NULL")
      end
    end

    def string_scopes(*attrs)
      define_scopes([:string, :text], attrs) do |attr|
        key = "#{table_name}.#{attr}"
        eq_scope = ->(*vals) { vals.empty? ? where("#{key} IS NOT NULL") : where(key => vals.flatten) }
        scope "with_#{attr}",    eq_scope
        scope "without_#{attr}", where("#{key} IS NULL")
        scope "#{attr}_eq",      eq_scope
        scope "#{attr}_ne",    ->(*vals) {
          raise ArgumentError, "No argument for for_#{attr} scope" if vals.empty?
          sql = "#{key} " << (vals.size == 1 && !vals[0].is_a?(Array) ? '!= ?' : 'NOT IN (?)') << " OR #{key} IS NULL"
          where(sql, vals.flatten)
        }
        scope "#{attr}_like",  ->(val) { where("#{key} LIKE ?", "%#{val}%") }

        ilike_scope = if connection.adapter_name == 'PostgreSQL'
          ->(val){ where("#{key} ILIKE ?", "%#{val}%") }
        else
          ->(val){ where("LOWER(#{key}) LIKE ?", "%#{val}%") }
        end
        scope "#{attr}_ilike", ilike_scope

        scope "by_#{attr}",      order("#{attr} ASC")
        scope "by_#{attr}_desc", order("#{attr} DESC")
      end
    end

    def assoc_scopes(*attrs)
      def extract_ids(val, attr)
        if val.is_a?(Fixnum) || (val.is_a?(String) && val.to_i != 0)
          val
        elsif val.is_a?(ActiveRecord::Base)
          val.id
        elsif val.is_a?(Array) && val.all? { |v| v.is_a?(Fixnum) || (v.is_a?(String) && v.to_i != 0) || v.is_a?(ActiveRecord::Base) }
          val.is_a?(ActiveRecord::Base) ? val.map(&:id) : val
        else
          raise ArgumentError, "Wrong argument type #{attr.class.name} for argument #{attr}"
        end
      end

      def extract_ids_and_types(val, attr)
        if val.is_a?(ActiveRecord::Base)
          {id: val.id, type: val.class.name}
        elsif val.is_a?(Hash) && val.assert_valid_keys(:id, :type)
          val
        elsif val.is_a?(Array) && val.all? { |v| v.is_a?(ActiveRecord::Base) }
          val.map { |v| {id: v.id, type: v.class.name} }
        elsif val.is_a?(Array) && val.size == 2 && id = val.find { |v| v.respond_to?(:to_i) && v.to_i != 0 }
          val.delete(id)
          {id: id, type: val[0]}
        else
          raise ArgumentError, "Wrong argument type #{attr.class.name} for argument #{attr}"
        end
      end

      attrs = reflections.keys if attrs.empty?
      attrs.each do |attr|
        if reflection = reflections[attr.to_sym]
          key = "#{table_name}.#{attr.to_s.foreign_key}"
          if reflection.options[:polymorphic]
            type_key = "#{table_name}.#{attr}_type"
            scope "for_#{attr}", ->(*vals) {
              raise ArgumentError, "No argument for for_#{attr} scope" if vals.empty?
              ids_and_types = vals.map { |v| extract_ids_and_types(v, attr) }.flatten
              conditions = ids_and_types.map { |hsh| "(#{key} = ? AND #{type_key} = ?)" }.join(' OR ')
              where(conditions, *ids_and_types.map(&:values).flatten)
            }
            scope "not_for_#{attr}", ->(*vals) {
              raise ArgumentError, "No argument for for_#{attr} scope" if vals.empty?
              ids_and_types = vals.map { |v| extract_ids_and_types(v, attr) }.flatten
              conditions = ids_and_types.map { |hsh| "(#{key} != ? AND #{type_key} != ?)" }.join(' AND ')
              where("#{conditions} OR (#{key} IS NULL OR #{type_key} IS NULL)", *ids_and_types.map(&:values).flatten)
            }
          else
            scope "for_#{attr}", ->(*vals) {
              raise ArgumentError, "No argument for for_#{attr} scope" if vals.empty?
              where("#{table_name}.#{attr.to_s.foreign_key}" => vals.map { |v| extract_ids(v, attr) }.flatten )
            }
            scope "not_for_#{attr}", ->(*vals) {
              raise ArgumentError, "No argument for for_#{attr} scope" if vals.empty?
              ids = vals.map { |v| extract_ids(v, attr) }.flatten
              conditions = ids.size == 1 ? "!= ?" : "NOT IN (?)"
              where("#{key} #{conditions} OR #{key} IS NULL", ids.size == 1 ? ids[0] : ids)
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
              key = "#{table_name}.#{attr}"
              state = "nil_#{attr}" if state.nil?
              scope state,          where("#{key}" => state)
              scope "not_#{state}", where("#{key} != ? OR #{table_name}.#{attr} IS NULL", state)
              scope "with_#{attr}",    where("#{key} IS NOT NULL")
              scope "without_#{attr}", where("#{key} IS NULL")
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
      assoc_scopes
      state_scopes if defined?(StateMachine)
    end

    private

    def reflections_for?(attr)
      !!reflections[attr.to_s.sub(/_(id|type)$/, '').to_sym]
    end

    def define_scopes(types, attrs, &block)
      types = Array.wrap(types)
      attrs = columns_hash.inject([]) do |ar, (attr, meta)|
        ar << attr if meta.type.in?(types) && !reflections_for?(attr) && (!defined?(StateMachine) || !state_machines[attr.to_sym])
        ar
      end if attrs.empty?

      attrs.each do |attr|
        begin
          if defined?(StateMachine) && state_machines[attr.to_sym]
            raise ArgumentError, "State machine column #{attr} used for value scope"
          elsif reflections_for?(attr)
            raise ArgumentError, "Association column #{attr} used for value scope"
          elsif (type = columns_hash[attr.to_s].type).in?(types)
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
