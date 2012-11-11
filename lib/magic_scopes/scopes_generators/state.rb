if defined?(StateMachine)
  module MagicScopes
    class StateScopesGenerator < ScopesGenerator::Base
      def initialize(model, state)
        @model = model
        @state = state
        @key   = "#{model.table_name}.#{attr}"
      end

      def is(name)
        scope name || @state, where("#{@key}" => @state)
      end

      def not(name)
        scope name || "not_#{@state}", where("#{@key} != ? OR #{@key} IS NULL", @state)
      end

      def with(name)
        @model.instance_eval("undef :with_#{attr}") unless name
        scope name || "with_#{@attr}", ->(*vals) { where(vals.empty? ? "#{@key} IS NOT NULL" : ["#{@key} IN (?)", vals]) }
      end

      def without(name)
        @model.instance_eval("undef :without_#{attr}") unless name
        scope name || "without_#{@attr}", ->(*vals) { where(vals.empty? ? "#{@key} IS NULL" : ["#{@key} NOT IN (?)", vals]) }
      end

      private

      def attr
        @attr ||= @model.state_machines.find { |_, sm| sm.states.map(&:name).include?(@state) }[0]
      end
    end
  end
end
