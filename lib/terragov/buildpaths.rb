require_relative 'cli'

module Terragov
  class BuildPaths

    def base(options={})

      environment = options['environment']
      data_dir = options['data_dir']
      repo_dir = options['repo_dir']
      stack = options['stack']
      project = options['project']
      extra   = options['extra']

      $terraform_dir              = File.join(repo_dir, "terraform")
      $project_dir                = File.join($terraform_dir, "projects/#{project}")
      $backend_file               = File.join($project_dir, "#{environment}.#{stack}.backend")
      $common_data_dir            = File.join($data_dir, "common/#{environment}")
      $common_data                = File.join($common_data_dir, "common.tfvars")
      $stack_common_data          = File.join($common_data_dir, "#{stack}.tfvars")
      $project_data_dir           = File.join($data_dir, "#{project}/#{environment}")
      $common_project_data        = File.join($project_data_dir, "common.tfvars")
      $secret_common_project_data = File.join($project_data_dir, "common.secret.tfvars")
      $stack_project_data         = File.join($project_data_dir, "#{stack}.tfvars")
      $secret_project_data        = File.join($project_data_dir, "#{stack}.secret.tfvars")
    end

    def data_validation(path, required = false)
      if required
        if File.exist?(path)
          return true
        else
          abort("Invalid directory or file: #{path}")
        end
      else
        if File.exist?(path)
          return true
        else
          return false
        end
      end
    end

    def backend
      return $backend_file if data_validation($backend_file, true)
    end

    def project_dir
      return $project_dir if data_validation($project_dir, true)
    end

    def data_paths
      # The path order is important for passing the var files in the correct
      # order to Terraform as that creates the hierarchy for overrides
      paths = [
        $common_data,
        $stack_common_data,
        $common_project_data,
        $secret_common_project_data,
        $stack_project_data,
        $secret_project_data,
      ]
    end

    def check_var_files
      $path_array = []
      data_paths.each do |path|
        $path_array << data_validation(path)
      end

      unless $path_array.include? true
        puts "Error: No tfvars file found"
        puts "Files checked: "
        paths.each do |path|
          puts path
        end
        exit 1
      end
    end

    def build_command
      abort("Cannot find main repository") unless data_validation($terraform_dir, true)
      check_var_files

      $full_vars = []
      data_paths.each do |path|
        if data_validation(path)
          # TODO: write sops class
          if path == $secret_project_data || path == $secret_common_project_data
            #@full_vars << "-var-file" + Terragov::Sops.new.decrypt(path)
            #$full_vars << "-var-file #{path}"
          else
            $full_vars << "-var-file #{path}"
          end
        end
      end
      return $full_vars.join(" ")
    end

    def vars(options={})
      base(options)
      build_command
    end
  end
end
