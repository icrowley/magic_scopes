module MagicScopes
  class ScopesBuilder

    include MagicScopes::StandardScopes

    STANDARD_OPTIONS = [:std, :in, :ex]

    MAGIC_SCOPES = {
      boolean:     [:is, :not, :with, :without],
      integer:     [:with, :without, :eq, :ne, :gt, :gte, :lt, :lte, :by, :by_desc],
      float:       [:with, :without, :lt, :gt, :by, :by_desc],
      string:      [:with, :without, :eq, :ne, :by, :by_desc, :like, :not_like, :ilike, :not_ilike],
      association: [:for, :not_for]
    }
    MAGIC_SCOPES[:state]   = MAGIC_SCOPES[:boolean]
    MAGIC_SCOPES[:decimal] = MAGIC_SCOPES[:time] = MAGIC_SCOPES[:datetime] = MAGIC_SCOPES[:date] = MAGIC_SCOPES[:integer]
    MAGIC_SCOPES[:text]    = MAGIC_SCOPES[:string]

    delegate :scope, :order, :columns_hash, :reflections, :state_machines, to: :@model

    def initialize(model, *attrs)
      @model   = model
      @options = attrs.extract_options!.symbolize_keys
      check_options
      @attributes_with_scopes = extract_attributes_with_scopes
      @attributes             = make_attributes(attrs)
      @is_attributes_passed   = attrs.present? || @attributes_with_scopes.present?
      @needed_scopes          = make_needed_scopes
    end

    def generate_standard_scopes
      (@options[:std] || STANDARD_SCOPES).each { |scope_type| send("#{scope_type}_scope") }
    end

    def generate_scopes
      @attributes.inject({}) { |hsh, attr| hsh[attr] = generate_scopes_for_attr(attr, @needed_scopes); hsh }.merge(
        @attributes_with_scopes.inject({}) { |hsh, (attr, attr_scopes)| hsh[attr] = generate_scopes_for_attr(attr, attr_scopes); hsh }
      )
    end


    private

    def generate_scopes_for_attr(attr, scopes)
      scopes.inject([]) do |ar, scope_type|
        if has_scope_generator_for?(attr, scope_type)
          generate_scope_for(attr, scope_type)
          ar << scope_type
        end
        ar
      end
    end

    def check_options
      @options.assert_valid_keys(*valid_options)

      if @options[:in] && @options[:ex]
        raise ArgumentError, "In(clude) and ex(clude) options can not be specified simultaneously"
      end

      if @options[:std] && option = @options[:std].find { |opt| STANDARD_SCOPES.exclude?(opt.to_sym) }
        raise ArgumentError, "Unknown option #{option} passed to magic_scopes#std"
      end
    end

    def extract_attributes_with_scopes
      attributes_with_scopes = @options.inject({}) do |hsh, (option_key, options)|
        hsh[option_key] = Array.wrap(@options.delete(option_key)).map(&:to_sym) unless option_key.in?(STANDARD_OPTIONS)
        hsh
      end
      extract_states_from_attrs!(attributes_with_scopes)

      wrong_scope = nil
      if wrong_attr = attributes_with_scopes.find do |attr, attr_scopes|
        wrong_scope = attr_scopes.find { |st| scope_types(attr).exclude?(st.to_sym) }
      end
        raise ArgumentError, "Unknown scope #{wrong_scope} for attribute #{wrong_attr[0]} passed to magic_scopes"
      end

      attributes_with_scopes
    end

    def valid_options
      @valid_options ||= (STANDARD_OPTIONS + columns_hash.keys + reflections.keys).map(&:to_sym)
    end

    def scope_types(*attrs)
      filtered_scopes = if attrs.empty?
          MAGIC_SCOPES
        else
          needed_attr_types = attrs.map { |attr| attrs_with_types[attr] }
          MAGIC_SCOPES.select { |k, _| k.in?(needed_attr_types)  }
        end
      filtered_scopes.values.flatten.uniq
    end

    def make_attributes(attrs)
      attributes = if attrs.empty?
          all_possible_attributes - @attributes_with_scopes.keys
        else
          extract_states_from_attrs(attrs.map(&:to_sym))
        end

      if wrong_attr = attributes.find { |attr| all_possible_attributes.exclude?(attr) }
        raise ActiveRecord::UnknownAttributeError, "Unknown attribute #{wrong_attr} passed to magic_scopes"
      end
      if attr = attributes.find { |attr| @attributes_with_scopes.keys.include?(attr) }
        raise ArgumentError, "Attribute #{attr} specified using both list and hash"
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
          scope_types(*@attributes) - scopes_options
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

    def all_possible_attributes
      @all_possible_attributes ||= extract_states_from_attrs(columns_hash.keys.map(&:to_sym) + reflections.keys)
    end

    def extract_states_from_attrs(attrs)
      if defined?(StateMachine)
        machines = state_machines.keys
        if attrs.is_a?(Array)
          attrs += machines.inject([]) do |ar, sm_key|
            ar += state_machines[sm_key].states.map(&:name).compact if sm_key.in?(attrs)
            ar
          end
          attrs -= machines
        else
          machines_states = machines.inject(attrs) do |hsh, sm_key|
            state_machines[sm_key].states.map(&:name).compact.each { |state| hsh[state] = attrs[sm_key] } if sm_key.in?(attrs)
            hsh
          end
          attrs.except!(*machines)
        end
      end
      attrs
    end

    def extract_states_from_attrs!(attrs)
      attrs = extract_states_from_attrs(attrs)
    end

    def attrs_with_types
      @attrs_with_types ||= all_possible_attributes.inject({}) do |hsh, attr|
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
