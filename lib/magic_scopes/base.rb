module MagicScopes::Base

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

      filters = options[:in] || options[:ex]
      filters = Array.wrap(filters).map(&:to_sym) if filters

      if filters && !filters.all? { |scope_type| scope_type.in?(magic_scopes_list) }
        raise ArgumentError, "Wrong scope passed to magic_scopes"
      end

      needed_scopes = if options[:in]
          filters
        elsif options[:ex]
          magic_scopes_list - filters
        else
          magic_scopes_list
        end

      if attrs.empty?
        attrs = attrs_list
      else
        attrs = extract_states_from_attrs(attrs.map(&:to_sym))
        if filters && needed_scopes.any? { |scope_type| attrs.any? { |attr| !has_scope_generator_for?(attr, scope_type) } }
          raise ArgumentError, "Can not build scopes for all passed attributes"
        end
      end
      unless attrs.all? { |attr| attr.in?(attrs_list) }
        raise ActiveRecord::UnknownAttributeError, "Unknown attribute passed to magic_scopes"
      end

      attrs.inject({}) do |hsh, attr|
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

    def magic_scopes_list
      @magic_scopes_list ||= MAGIC_SCOPES.values.flatten.uniq
    end

    def attrs_list
      @attrs_list ||= begin
        attrs_list = columns_hash.keys.map(&:to_sym) + reflections.keys
        attrs_list = extract_states_from_attrs(attrs_list)
        attrs_list
      end
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
      @attrs_with_types ||= attrs_list.inject({}) do |hsh, attr|
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
