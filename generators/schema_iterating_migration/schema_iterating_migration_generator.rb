class SchemaIteratingMigrationGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      migration_template = 'migration:migration.rb'
      m.migration_template migration_template, 'db/migrate/schema_iterating_migration', :assigns => get_local_assigns
      m.migration_template migration_template, 'db/migrate', :assigns => get_local_assigns if options[:shared_migration]
    end
  end
  
  protected
    def add_options!(opt)
      opt.separator ''
      opt.separator 'Options:'
      opt.on("--shared-migration",
             "Generation a shared migration file as well") { |v| options[:shared_migration] = v}
      
    end
  
  private  
    def get_local_assigns
      returning(assigns = {}) do
        if class_name.underscore =~ /^(add|remove)_.*_(?:to|from)_(.*)/
          assigns[:migration_action] = $1
          assigns[:table_name]       = $2.pluralize
        else
          assigns[:attributes] = []
        end
      end
    end
end
