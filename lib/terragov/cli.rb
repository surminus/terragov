require 'commander'
require 'yaml'
require_relative 'buildpaths'
require_relative 'terraform'
require_relative 'cleaner'

module Terragov
  class Cli
    include Commander::Methods

    def initialize
      program :name, 'terragov'
      program :version, Terragov::VERSION
      program :description, 'Wrapper for GOV.UK Terraform deployments.'

      global_option('-c', "--config-file FILE", 'Specify a config file. Has less precedence than environment variables, which in turn have left precedence than CLI options') do |config_file|
        $config_file = config_file
      end

      global_option('-d', "--data-dir DIRECTORY", 'Location of the data directory') do |data_dir|
        $data_dir = data_dir
      end

      global_option( '-e', '--env STRING', String, 'Select environment') do |env|
        $environment = env
      end

      global_option(  '-p', '--project STRING', String, 'Name of the project') do |project|
        $project = project
      end

      global_option( '-r', '--repo-dir DIRECTORY', String, 'Location of the main terraform repository') do |repo_dir|
        $repo_dir = repo_dir
      end

      global_option( '-s', '--stack STRING', String, 'Name of the stack') do |stack|
        $stack = stack
      end

      global_option('--extra STRING', String, 'Any additional arguments to pass in the following format: --extra \\\\-target resource.foo.') do |extra|
        $extra = extra
      end

      global_option('--verbose', String, 'Verbose mode') do |verbose|
        $verbose = verbose
      end

      global_option('--dry-run', String, 'Verbose mode', 'Output the commands to run, but do not run them') do |dryrun|
        $dryrun = dryrun
      end

    end

    def load_config_file
      if $config_file || ENV['TERRAGOV_CONFIG_FILE']
        file = $config_file || ENV['TERRAGOV_CONFIG_FILE']
        $values = YAML.load_file(File.expand_path(file))
      end
      return $values
    end

    def data_dir
      error_message = "Must provided the data directory. See --help for details"
      if $data_dir
        return File.expand_path($data_dir)
      elsif ENV['TERRAGOV_DATA_DIR']
        return File.expand_path(ENV['TERRAGOV_DATA_DIR'])
      elsif load_config_file['data_dir']
        return File.expand_path(load_config_file['data_dir'])
      else
        abort(error_message)
      end
    end

    def environment
      error_message = "Must set AWS environment. Use --help for details"
      if $environment
        return $environment
      elsif ENV['TERRAGOV_ENVIRONMENT']
        return ENV['TERRAGOV_ENVIRONMENT']
      elsif load_config_file['environment']
        return load_config_file['environment']
      else
        abort(error_message)
      end
    end

    def project
      error_message = "Must set AWS project. Use --help for details"

      if $project
        return $project
      elsif ENV['TERRAGOV_PROJECT']
        return ENV['TERRAGOV_PROJECT']
      elsif load_config_file['project']
        return load_config_file['project']
      else
        abort(error_message)
      end
    end

    def repo_dir

      if $repo_dir
        return File.expand_path($repo_dir)
      elsif ENV['TERRAGOV_REPO_DIR']
        return File.expand_path(ENV['TERRAGOV_REPO_DIR'])
      elsif load_config_file['repo_dir']
        return File.expand_path(load_config_file['repo_dir'])
      else
        return File.expand_path('.')
      end
    end

    def stack
      error_message = "Must set AWS stackname. Use --help for details"

      if $stack
        return $stack
      elsif ENV['TERRAGOV_STACK']
        return ENV['TERRAGOV_STACK']
      elsif load_config_file['stack']
        return load_config_file['stack']
      else
        abort(error_message)
      end
    end

    def extra
      return $extra if $extra
    end

    def cmd_options
      cmd_options_hash = {
        "environment" => environment,
        "data_dir"    => data_dir,
        "project"     => project,
        "stack"       => stack,
        "repo_dir"    => repo_dir,
        "extra"       => extra,
      }
      return cmd_options_hash
    end

    def run_terraform_cmd(cmd, opt = nil)
      paths = Terragov::BuildPaths.new.base(cmd_options)
      varfiles = Terragov::BuildPaths.new.build_command(cmd_options)
      backend  = paths[:backend_file]
      project_dir = paths[:project_dir]
      if opt
        cmd = "#{cmd} #{opt}"
      end
      Terragov::Terraform.new.execute(cmd, varfiles, backend, project_dir)
    end

    def run
      command :plan do |c|
        c.syntax = 'terragov plan'
        c.description = 'Runs a plan of your code'
        c.action do |args, options|
          if options.verbose
            ENV['TERRAGOV_VERBOSE'] = "true"
            puts "Planning..."
            puts cmd_options.to_yaml
          end

          if options.dry_run
            ENV['TERRAGOV_DRYRUN'] = "true"
          end

          run_terraform_cmd(c.name)
        end
      end

      command :apply do |c|
        c.syntax = 'terragov apply'
        c.description = 'Apply your code'
        c.action do |args, options|
          if options.verbose
            ENV['TERRAGOV_VERBOSE'] = "true"
            puts "Applying..."
            puts cmd_options.to_yaml
          end

          if options.dry_run
            ENV['TERRAGOV_DRYRUN'] = "true"
          end

          run_terraform_cmd(c.name)
        end
      end

      command :destroy do |c|
        c.syntax = 'terragov destroy'
        c.description = 'Destroy your selected project'
        c.option '--force', 'Force destroy'
        c.action do |args, options|
          if options.verbose
            ENV['TERRAGOV_VERBOSE'] = "true"
            puts "Destroying..."
            puts cmd_options.to_yaml
          end

          if options.dry_run
            ENV['TERRAGOV_DRYRUN'] = "true"
          end

          if options.force
            run_terraform_cmd("#{c.name} -force")
          else
            run_terraform_cmd(c.name)
          end
        end
      end

      command :clean do |c|
        c.syntax = 'terragov clean'
        c.description = 'Clean your directory of any files terraform may have left lying around'
        c.option '--force', 'Force removal of files'
        c.action do |args, options|
          if options.verbose
            puts "Selecting directory #{repo_dir}"
          end

          Terragov::Cleaner.new.delete(repo_dir, /terraform\.tfstate\.backup/, options.force)
        end
      end

      run!
    end
  end
end
