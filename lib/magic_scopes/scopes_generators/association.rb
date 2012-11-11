module MagicScopes
  class AssociationScopesGenerator < ScopesGenerator::Base

    def initialize(model, attr)
      super
      @model    = model
      @attr     = attr
      @key      = "#{model.table_name}.#{attr.to_s.foreign_key}"
      @type_key = "#{model.table_name}.#{attr}_type"
    end

    def for(name)
      if @model.reflections[@attr].options[:polymorphic]
        scope name || "for_#{@attr}", ->(*vals) {
          raise ArgumentError, "No argument for for_#{@attr} scope" if vals.empty?
          ids_and_types = vals.map { |v| extract_ids_and_types(v, @attr) }.flatten
          conditions = ids_and_types.map { |hsh| "(#{@key} = ? AND #{@type_key} = ?)" }.join(' OR ')
          where(conditions, *ids_and_types.map(&:values).flatten)
        }
      else
        scope name || "for_#{@attr}", ->(*vals) {
          raise ArgumentError, "No argument for for_#{@attr} scope" if vals.empty?
          where(@key => vals.map { |v| extract_ids(v, @attr) }.flatten )
        }
      end
    end

    def not_for(name)
      if @model.reflections[@attr.to_sym].options[:polymorphic]
        scope name || "not_for_#{@attr}", ->(*vals) {
          raise ArgumentError, "No argument for for_#{@attr} scope" if vals.empty?
          ids_and_types = vals.map { |v| extract_ids_and_types(v, @attr) }.flatten
          conditions = ids_and_types.map { |hsh| "(#{@key} != ? AND #{@type_key} != ?)" }.join(' AND ')
          where("#{conditions} OR (#{@key} IS NULL OR #{@type_key} IS NULL)", *ids_and_types.map(&:values).flatten)
        }
      else
        scope name || "not_for_#{@attr}", ->(*vals) {
          raise ArgumentError, "No argument for for_#{@attr} scope" if vals.empty?
          ids = vals.map { |v| extract_ids(v, @attr) }.flatten
          conditions = ids.size == 1 ? "!= ?" : "NOT IN (?)"
          where("#{@key} #{conditions} OR #{@key} IS NULL", ids.size == 1 ? ids[0] : ids)
        }
      end
    end


    private

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
  end
end
