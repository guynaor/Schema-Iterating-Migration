#copy the config template to RAILS_ROOT/config folder
config_file = "#{RAILS_ROOT}/config/schema_iterating_migration_conf.yml"
FileUtils.cp("#{File.dirname(__FILE__)}/schema_iterating_migration_conf.yml.tmpl", config_file) unless File.exists?(config_file)
