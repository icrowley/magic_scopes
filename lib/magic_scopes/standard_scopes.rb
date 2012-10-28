module MagicScopes
  module StandardScopes
    extend ActiveSupport::Concern

    included do
      self::STANDARD_SCOPES = [:asc, :sorted, :desc, :recent, :random]
    end

    private

    def asc_scope
      scope :asc, order(:id)
    end

    def sorted_scope
      scope :sorted, order(:id)
    end

    def desc_scope
      scope :desc,  order('id DESC')
    end

    def recent_scope
      scope :recent, order('id DESC')
    end

    def random_scope
      scope :random, order('RANDOM()')
    end
  end
end
