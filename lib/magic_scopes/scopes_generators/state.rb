if defined?(StateMachine)
  module MagicScopes
    class StateScopesGenerator < ScopesGenerator::Base
      def initialize(model, state)
        @model = model
        @state = state
        @key   = "#{model.table_name}.#{attr}"
        model.instance_eval("undef :with_#{attr}")
        model.instance_eval("undef :without_#{attr}")
      end

      def is
        scope @state, where("#{@key}" => @state)
      end

      def not
        scope "not_#{@state}", where("#{@key} != ? OR #{@key} IS NULL", @state)
      end

      def with
        scope "with_#{@attr}", ->(*vals) { where(vals.empty? ? "#{@key} IS NOT NULL" : ["#{@key} IN (?)", vals]) }
      end

      def without
        scope "without_#{@attr}", ->(*vals) { where(vals.empty? ? "#{@key} IS NULL" : ["#{@key} NOT IN (?)", vals]) }
      end

      private

      def attr
        @attr ||= @model.state_machines.find { |_, sm| sm.states.map(&:name).include?(@state) }[0]
      end
    end
  end
end
