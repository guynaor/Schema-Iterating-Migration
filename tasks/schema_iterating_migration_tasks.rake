# add a delete_task method to the TaskManager and delete db:migrate
Rake::TaskManager.class_eval do
  def delete_task(task_name)
    @tasks.delete(task_name.to_s)
  end
  %w{db:migrate db:migrate:up db:migrate:down db:rollback}.each {|t| Rake.application.delete_task(t) }
end

#define a new db:migrate. add an option to specify if you want to do a migration
#of schema_iterating migration by specifying SIM=true (SIM==SchemaIteratingMigration)
#without the option above, it will just do migration files under db/migrate -- the shared schema
namespace :db do
  desc "Migrate the database through scripts in db/migrate or specify SIM=true to do migration files under db/migrate/schema_iterating_migration. Target specific version with VERSION=x."
  task :migrate => :environment do
    ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
    version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
    do_schemas_iterating_migrations {|path| ActiveRecord::Migrator.migrate(path, version) }    
  end  
  
  desc 'Rolls the schema back to the previous version. Specify the number of steps with STEP=n. Specify SIM=true if for schema_iterating_migration.'
  task :rollback => :environment do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    do_schemas_iterating_migrations {|path|  ActiveRecord::Migrator.rollback(path, step) }    
  end  
  
  namespace :migrate do
    desc 'Runs the "up" for a given migration VERSION. Add SIM=true if for schema_iterating_migration.'
    task :up => :environment do
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version
      do_schemas_iterating_migrations {|path|  ActiveRecord::Migrator.run(:up, path, version) }    
    end

    desc 'Runs the "down" for a given migration VERSION. Add SIM=true if for schema_iterating_migration.'
    task :down => :environment do
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version
      do_schemas_iterating_migrations {|path|  ActiveRecord::Migrator.run(:down, path, version) }    
    end    
  end  
end
 
def add_schema_to_search_path(sc)
  conn ActiveRecord::Base.connection
  saved_path = conn.execute("SHOW search_path")[0][0] # Save current path
  schema_set = schema.downcase == saved_path.split(',').first.strip.downcase # If it's set we don't do much here...
  conn.execute(%Q<SET search_path TO "#{schema}", #{conn.schema_search_path}>) if !schema_set
end
 
def do_schemas_iterating_migrations
  if ENV['SIM']
    sim_plugin_config ||= YAML.load(File.open("#{RAILS_ROOT}/config/schema_iterating_migration_conf.yml"))
    sites_schemas = Object.const_get(sim_plugin_config[:class_name]).send(sim_plugin_config[:field_name]) rescue []
    orig_path = ActiveRecord::Base.connection.schema_search_path
    sites_schemas.each do|schema_name| 
      puts "== Migrating schema: #{schema_name} =="
      add_schema_to_search_path(schema_name)
      yield('db/migrate/schema_iterating_migration') 
      # Reset search path to the origin
      conn.execute("SET search_path TO #{conn.schema_search_path}")
    end
  else
    yield('db/migrate')
  end
end
  
