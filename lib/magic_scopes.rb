require 'magic_scopes/version'
require 'magic_scopes/railtie' if defined?(Rails)

# interface:
# magic_scopes *attrs
# magic_scopes :rating, :age, :first_name, :last_name, in: %w(gt lt ne), std: %w(desc random)

module MagicScopes

  extend ActiveSupport::Concern

  MAGIC_SCOPES = {
    boolean:     [:is, :not, :with, :without],
    integer:     [:with, :without, :eq, :ne, :gt, :gte, :lt, :lte, :by, :by_desc],
    float:       [:with, :without, :lt, :gt, :by, :by_desc],
    string:      [:with, :without, :eq, :ne, :by, :by_desc, :like, :ilike],
    association: [:for, :not_for]
  }
  MAGIC_SCOPES[:state]   = MAGIC_SCOPES[:boolean]
  MAGIC_SCOPES[:decimal] = MAGIC_SCOPES[:time] = MAGIC_SCOPES[:datetime] = MAGIC_SCOPES[:date] = MAGIC_SCOPES[:integer]
  MAGIC_SCOPES[:text]    = MAGIC_SCOPES[:string]

  module ClassMethods

    def magic_scopes(*attrs)
      options = attrs.extract_options!

      if options[:in] && options[:ex]
        raise ArgumentError, "In(clude) and ex(clude) options can not be specified simultaneously"
      end

      filter = options[:in] || options[:ex]

      if filter && !Array.wrap(filter).all? { |scope_type| scope_type.to_sym.in?(magic_scopes_list) }
        raise ArgumentError, "Wrong scope passed to magic_scopes"
      end

      if attrs.empty?
        attrs = attrs_list
      else
        attrs = attrs.map(&:to_sym)
        if filter && filter.any? { |scope_type| attrs.any? { |attr| scope_type.in?(MAGIC_SCOPES[attrs_with_types[attr]]) } }
          raise ArgumentError, "Can not build scopes for all passed attributes"
        end
      end
      unless attrs.all? { |attr| attr.to_sym.in?(attrs_list) }
        raise ActiveRecord::UnknownAttributeError, "Unknown attribute passed to magic_scopes"
      end

      attrs
    end

    private

    def magic_scopes_list
      @magic_scopes_list ||= MAGIC_SCOPES.values.flatten.uniq
    end

    def attrs_list
      @attrs_list ||= begin
        states = if defined?(StateMachine)
            state_machines.keys.inject([]) do |ar, sm_key|
              ar += state_machines[sm_key].states.map(&:name).map { |el| el || "nil_#{sm_key}" }
              ar
            end
          end
        (columns_hash.keys + reflections.keys + (states || [])).map(&:to_sym)
      end
    end

    def attrs_with_types
      @attrs_with_types ||= attrs_list.inject({}) do |hsh, attr|
        if reflections[attr]
          :association
        elsif type = columns_hash[attr.to_s].try(:type)
          type
        else
          :state
        end
        hsh
      end
    end

    def asc_scope
      scope :asc,    order(:id)
      scope :sorted, order(:id)
    end
    alias :sorted_scope :asc_scope

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
  end
end
