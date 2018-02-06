module Terragov
  class Config
    def project_name
      $project || ENV['TERRAGOV_PROJECT']
    end

    def load_config_file
      file = $config_file || ENV['TERRAGOV_CONFIG_FILE']
      YAML.load_file(File.expand_path(file)) if file
    end

    def config_file_default
      return nil if load_config_file['default'].nil?
      load_config_file['default']
    end

    def config_file_specific_project(project_name)
      load_config_file[project_name]
    end

    def config_file(option)
      if project_name.nil?
        if config_file_default.nil?
          return nil
        else
          return config_file_default[option]
        end
      else
        project_config = config_file_specific_project(project_name)
        if project_config.nil? or project_config[option].nil?
          return config_file_default[option]
        else
          return project_config[option]
        end
      end
    end

    def lookup(settings = {})
      # Structure of hash should be:
      #
      # name: Name of the item to lookup
      # cli:  Result of CLI options
      # required: whether or not it's required (default: true)
      # file: whether to return a file path

      default = {
        cli: false,
        required: true,
        file: false,
      }

      settings = default.merge(settings)

      env_var = "TERRAGOV_#{settings[:name].upcase}"
      error_message = "Must set #{settings[:name]}. Use --help for details."

      # Load from CLI option
      if settings[:cli]
        return File.expand_path(settings[:cli]) if settings[:file]
        return settings[:cli]
      end

      # Load from environment variable
      if ENV[env_var]
        return File.expand_path(ENV[env_var]) if settings[:file]
        return ENV[env_var]
      end

      # Return error/false if config_file isn't available
      if load_config_file.nil?
        abort(error_message) if settings[:required]
        return false
      end

      # Return error/false if the specific option isn't available
      if config_file(settings[:name]).nil?
        abort(error_message) if settings[:required]
        return false
      end

      # Otherwise return the value from the config file
      return File.expand_path(config_file(settings[:name])) if settings[:file]
      config_file(settings[:name])
    end
  end
end
