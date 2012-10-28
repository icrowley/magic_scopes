module MagicScopes
  module Standard
    extend ActiveSupport::Concern

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
  end
end
