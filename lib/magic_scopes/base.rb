module MagicScopes::Base

  extend ActiveSupport::Concern

  include MagicScopes::StandardScopes

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
      options = attrs.extract_options!.symbolize_keys

      options.assert_valid_keys(*valid_options)

      if options[:std] && option = options[:std].find { |opt| self::STANDARD_SCOPES.exclude?(opt.to_sym) }
        raise ArgumentError, "Unknown option #{option} passed to magic_scopes#std"
      end

      (options[:std] || self::STANDARD_SCOPES).each { |scope_type| send("#{scope_type}_scope") }

      if options[:in] && options[:ex]
        raise ArgumentError, "In(clude) and ex(clude) options can not be specified simultaneously"
      end

      passed_scope_types = options[:in] || options[:ex]
      passed_scope_types = if passed_scope_types
        passed_scope_types = Array.wrap(passed_scope_types).map(&:to_sym)
        if wrong_scope = passed_scope_types.find { |scope_type| all_scope_types.exclude?(scope_type) }
          raise ArgumentError, "Unknown scope #{wrong_scope} passed to magic_scopes"
        end
        passed_scope_types
      end

      attributes = attrs.empty? ? all_possible_attrs : extract_states_from_attrs(attrs.map(&:to_sym))
      if wrong_attr = attributes.find { |attr| all_possible_attrs.exclude?(attr) }
        raise ActiveRecord::UnknownAttributeError, "Unknown attribute #{wrong_attr} passed to magic_scopes"
      end

      needed_scopes = if options[:in]
          passed_scope_types
        elsif options[:ex]
          all_scope_types(attributes) - passed_scope_types
        else
          all_scope_types
        end

      if passed_scope_types && !attrs.empty? && wrong_scope = needed_scopes.find { |scope_type| attributes.any? { |attr| !has_scope_generator_for?(attr, scope_type) } }
        raise ArgumentError, "Can not build scope #{wrong_scope} for all passed attributes"
      end

      attributes.inject({}) do |hsh, attr|
        hsh[attr] = needed_scopes.inject([]) do |ar, scope_type|
          if has_scope_generator_for?(attr, scope_type)
            generate_scope_for(attr, scope_type)
            ar << scope_type
          end
          ar
        end
        hsh
      end
    end

    private

    def valid_options
      @valid_options ||= (%w(std in ex) + columns_hash.keys + reflections.keys).map(&:to_sym)
    end

    def generate_scope_for(attr, scope_type)
      type = type_for_attr(attr)
      "MagicScopes::#{type.to_s.classify}ScopesGenerator".constantize.instance(self, attr).send(scope_type)
    end

    def has_scope_generator_for?(attr, scope_type)
      scope_type.in?(MAGIC_SCOPES[type_for_attr(attr)])
    end

    def type_for_attr(attr)
      attrs_with_types[attr]
    end

    def all_scope_types(attrs = nil)
      filtered_scopes = unless attrs
          MAGIC_SCOPES
        else
          needed_types = attrs.map { |attr| attrs_with_types[attr] }
          MAGIC_SCOPES.select { |k, _| k.in?(needed_types)  }
        end
      filtered_scopes.values.flatten.uniq
    end

    def all_possible_attrs
      @all_possible_attrs ||= all_possible_attrs = extract_states_from_attrs(columns_hash.keys.map(&:to_sym) + reflections.keys)
    end

    def extract_states_from_attrs(attrs)
      if defined?(StateMachine)
        machines = state_machines.keys
        attrs += machines.inject([]) do |ar, sm_key|
            ar += state_machines[sm_key].states.map(&:name).compact if sm_key.in?(attrs)
            ar
          end
        attrs -= machines
      end
      attrs
    end

    def attrs_with_types
      @attrs_with_types ||= all_possible_attrs.inject({}) do |hsh, attr|
        hsh[attr] = if reflections[attr]
            :association
          elsif (type = columns_hash[attr.to_s].try(:type)) && (!defined?(StateMachine) || !state_machines.keys.include?(attr))
            type
          else
            :state
          end
        hsh
      end
    end
  end
end
