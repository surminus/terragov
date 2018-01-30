require_relative 'cli'

module Terragov
  class BuildPaths
    def base(options = {})
      environment = options['environment']
      data_dir = options['data_dir']
      repo_dir = options['repo_dir']
      stack = options['stack']
      project = options['project']
      extra   = options['extra']

      # Construct variables
      terraform_dir               = File.join(repo_dir, 'terraform')
      project_dir                 = File.join(terraform_dir, "projects/#{project}")
      backend_file                = File.join(project_dir, "#{environment}.#{stack}.backend")
      common_data_dir             = File.join(data_dir, "common/#{environment}")
      all_env_common_data         = File.join(data_dir, 'common', 'common.tfvars')
      all_env_stack_common_data   = File.join(data_dir, 'common', "#{stack}.tfvars")
      common_data                 = File.join(common_data_dir, 'common.tfvars')
      stack_common_data           = File.join(common_data_dir, "#{stack}.tfvars")
      project_data_dir            = File.join(data_dir, "#{project}/#{environment}")
      all_env_common_project_data = File.join(data_dir, project, 'common.tfvars')
      all_env_stack_project_data  = File.join(data_dir, project, "#{stack}.tfvars")
      common_project_data         = File.join(project_data_dir, 'common.tfvars')
      secret_common_project_data  = File.join(project_data_dir, 'common.secret.tfvars')
      stack_project_data          = File.join(project_data_dir, "#{stack}.tfvars")
      secret_project_data         = File.join(project_data_dir, "#{stack}.secret.tfvars")

      # Return hash to enable testing
      data_paths = {
        terraform_dir: terraform_dir,
        project_dir: project_dir,
        backend_file: backend_file,
        common_data_dir: common_data_dir,
        all_env_common_data: all_env_common_data,
        all_env_stack_common_data: all_env_stack_common_data,
        common_data: common_data,
        stack_common_data: stack_common_data,
        project_data_dir: project_data_dir,
        all_env_common_project_data: all_env_common_project_data,
        all_env_stack_project_data: all_env_stack_project_data,
        common_project_data: common_project_data,
        secret_common_project_data: secret_common_project_data,
        stack_project_data: stack_project_data,
        secret_project_data: secret_project_data
      }
    end

    def data_validation(path)
      if File.exist?(path)
        true
      else
        false
      end
    end

    def data_paths(options = {})
      # The path order is important for passing the var files in the correct
      # order to Terraform as that creates the hierarchy for overrides
      base = self.base(options)
      paths = [
        base[:all_env_common_data],
        base[:all_env_stack_common_data],
        base[:common_data],
        base[:stack_common_data],
        base[:all_env_common_project_data],
        base[:all_env_stack_project_data],
        base[:common_project_data],
        base[:secret_common_project_data],
        base[:stack_project_data],
        base[:secret_project_data]
      ]
    end

    def check_var_files(paths = [])
      $path_array = []
      paths.each do |path|
        $path_array << data_validation(path)
      end

      if $path_array.include? true
        return true
      else
        puts 'Files checked: '
        paths.each do |path|
          puts path
        end
        return false
      end
    end

    def build_command(options = {})
      paths = base(options)
      abort("Error: cannot find main repository (#{paths[:terraform_dir]})") unless data_validation(paths[:terraform_dir])
      abort("Error: cannot find project (#{paths[:project_dir]}).") unless data_validation(paths[:project_dir])
      abort("Error: cannot find backend file (#{paths[:backend_file]}).\nDid you specify the right stack?") unless data_validation(paths[:backend_file])
      var_paths = data_paths(options)
      abort("Error: cannot find any var files") unless check_var_files(var_paths)

      $full_vars = []
      data_paths(options).each do |path|
        if data_validation(path)
          # TODO: write sops class
          if path == paths[:secret_project_data] || path == paths[:secret_common_project_data]
            $full_vars << "-var-file <(sops -d #{path})"
          else
            $full_vars << "-var-file #{path}"
          end
        end
      end
      # If defining additional Terraform commands, they need to be passed in as one string,
      # with any hyphens escaped twice so it does not conflict with commander CLI options
      extra = options['extra'].to_s
      $full_vars << extra.delete('\\')
      $full_vars.join(' ')
    end
  end
end
