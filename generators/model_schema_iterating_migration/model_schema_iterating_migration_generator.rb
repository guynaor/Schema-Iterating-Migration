class ModelSchemaIteratingMigrationGenerator < Rails::Generator::NamedBase
  default_options :skip_timestamps => false, :skip_migration => false, :skip_fixture => false

  def manifest
    record do |m|
      # Check for class naming collisions.
      m.class_collisions class_name, "#{class_name}Test"

      # Model, test, and fixture directories.
      m.directory File.join('app/models', class_path)
      m.directory File.join('test/unit', class_path)
      m.directory File.join('test/fixtures', class_path)

      # Model class, unit test, and fixtures.
      m.template 'model_schema_iterating_migration.rb',      File.join('app/models', class_path, "#{file_name}.rb")
      m.template 'model:unit_test.rb',  File.join('test/unit', class_path, "#{file_name}_test.rb")

      unless options[:skip_fixture] 
        m.template 'model:fixtures.yml',  File.join('test/fixtures', "#{table_name}.yml")
      end

      unless options[:skip_migration]
        migration_file_name = "create_#{file_path.gsub(/\//, '_').pluralize}"
        migration_name      = "Create#{class_name.pluralize.gsub(/::/, '')}"
        migration_template  = 'model:migration.rb'
        m.migration_template migration_template, 'db/migrate/schema_iterating_migration', :assigns => {
          :migration_name => migration_name}, :migration_file_name => migration_file_name
        m.migration_template migration_template, 'db/migrate', :assigns => {
            :migration_name => migration_name}, :migration_file_name => migration_file_name  if options[:shared_migration]
      end
    end
  end

  protected
    def banner
      "Usage: #{$0} #{spec.name} ModelName [field:type, field:type]"
    end

    def add_options!(opt)
      opt.separator ''
      opt.separator 'Options:'
      opt.on("--skip-timestamps",
             "Don't add timestamps to the migration file for this model") { |v| options[:skip_timestamps] = v }
      opt.on("--skip-migration", 
             "Don't generate a migration file for this model") { |v| options[:skip_migration] = v }
      opt.on("--skip-fixture",
             "Don't generation a fixture file for this model") { |v| options[:skip_fixture] = v}
     opt.on("--shared-migration",
            "Generation a shared migration file as well") { |v| options[:shared_migration] = v}
    end
    
end
