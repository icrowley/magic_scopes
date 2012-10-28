require 'rails/railtie'

module MagicScopes
  class Railtie < Rails::Railtie
    initializer 'magic_scopes.extend_active_record_base' do |app|
      ActiveSupport.on_load(:active_record) do
        send(:include, MagicScopes::Base)
      end
    end
  end
end
