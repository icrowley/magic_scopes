module MagicScopes
  module ScopesGenerator
    class Base

      @@instances = {}

      private_class_method :new

      def initialize(model, attr)
        @model = model
        @attr  = attr
        @key   = "#{model.table_name}.#{attr}"
      end

      def self.instance(model, attr)
        if @@instances[model.name].try(:has_key?, attr)
          @@instances[model.name][attr]
        else
          @@instances[model.name] ||= {}
          @@instances[model.name][attr] = new(model, attr)
        end
      end

      delegate :scope, :where, :order, to: :@model
    end
  end
end
