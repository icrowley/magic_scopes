module MagicScopes
  class ScopesBuilder

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

    delegate :scope, :order, :columns_hash, :reflections, :state_machines, to: :@model

    def initialize(model, *attrs)
      @model   = model
      @options = attrs.extract_options!.symbolize_keys
      @is_attributes_passed = !attrs.empty?
      check_options
      @attributes    = make_attributes(attrs)
      @needed_scopes = make_needed_scopes
    end

    def generate_standard_scopes
      (@options[:std] || STANDARD_SCOPES).each { |scope_type| send("#{scope_type}_scope") }
    end

    def generate_scopes
      @attributes.inject({}) do |hsh, attr|
        hsh[attr] = @needed_scopes.inject([]) do |ar, scope_type|
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

    def check_options
      @options.assert_valid_keys(*valid_options)

      if @options[:in] && @options[:ex]
        raise ArgumentError, "In(clude) and ex(clude) options can not be specified simultaneously"
      end

      if @options[:std] && option = @options[:std].find { |opt| STANDARD_SCOPES.exclude?(opt.to_sym) }
        raise ArgumentError, "Unknown option #{option} passed to magic_scopes#std"
      end
    end

    def valid_options
      @valid_options ||= (%w(std in ex) + columns_hash.keys + reflections.keys).map(&:to_sym)
    end

    def scope_types(attrs = nil)
      filtered_scopes = unless attrs
          MAGIC_SCOPES
        else
          needed_attr_types = attrs.map { |attr| attrs_with_types[attr] }
          MAGIC_SCOPES.select { |k, _| k.in?(needed_attr_types)  }
        end
      filtered_scopes.values.flatten.uniq
    end

    def make_attributes(attrs)
      attributes = attrs.empty? ? all_possible_attrs : extract_states_from_attrs(attrs.map(&:to_sym))
      if wrong_attr = attributes.find { |attr| all_possible_attrs.exclude?(attr) }
        raise ActiveRecord::UnknownAttributeError, "Unknown attribute #{wrong_attr} passed to magic_scopes"
      end
      attributes
    end

    def make_needed_scopes
      scopes_options = @options[:in] || @options[:ex]
      scopes_options = if scopes_options
        scopes_options = Array.wrap(scopes_options).map(&:to_sym)
        if wrong_scope = scopes_options.find { |scope_type| scope_types.exclude?(scope_type) }
          raise ArgumentError, "Unknown scope #{wrong_scope} passed to magic_scopes"
        end
        scopes_options
      end

      needed_scopes = if @options[:in]
          scopes_options
        elsif @options[:ex]
          scope_types(@attributes) - scopes_options
        else
          scope_types
        end

      if scopes_options && @is_attributes_passed && wrong_scope = check_for_wrong_scope(needed_scopes)
        raise ArgumentError, "Can not build scope #{wrong_scope} for all passed attributes"
      end

      needed_scopes
    end

    def check_for_wrong_scope(scopes)
      scopes.find { |scope_type| @attributes.any? { |attr| !has_scope_generator_for?(attr, scope_type) } }
    end

    def generate_scope_for(attr, scope_type)
      type = type_for_attr(attr)
      "MagicScopes::#{type.to_s.classify}ScopesGenerator".constantize.instance(@model, attr).send(scope_type)
    end

    def has_scope_generator_for?(attr, scope_type)
      scope_type.in?(MAGIC_SCOPES[type_for_attr(attr)])
    end

    def type_for_attr(attr)
      attrs_with_types[attr]
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
