require 'commander'
require 'yaml'
require_relative 'buildpaths'
require_relative 'terraform'

module Terragov
  class Cli
    include Commander::Methods

    def initialize
      program :name, 'terragov'
      program :version, Terragov::VERSION
      program :description, 'Wrapper for GOV.UK Terraform deployments.'

      global_option('-d', "--data-dir DIRECTORY", 'Location of the data directory') do |data_dir|
        $data_dir = data_dir
      end

      global_option( '-e', '--env STRING', String, 'Select environment') do |env|
        $env = env
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

      global_option('--extra STRING', String, 'Any additional arguments to pass in the following format: --extra \\-target resource.foo.') do |extra|
        $extra = extra
      end

      global_option('--verbose', String, 'Verbose mode') do |verbose|
        $verbose = verbose
      end

    end

    def data_dir
      error_message = "Must provided the data directory. See --help for details"
      if $data_dir
        return File.expand_path($data_dir)
      elsif ENV['TERRAGOV_DATA_DIR']
        return File.expand_path(ENV['TERRAGOV_DATA_DIR'])
      else
        abort(error_message)
      end
    end

    def env
      error_message = "Must set AWS environment. Use --help for details"
      if $env
        return $env
      elsif ENV['TERRAGOV_ENVIRONMENT']
        return ENV['TERRAGOV_ENVIRONMENT']
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
      else
        abort(error_message)
      end
    end

    def repo_dir

      if $repo_dir
        return File.expand_path($repo_dir)
      elsif ENV['TERRAGOV_REPO_DIR']
        return File.expand_path(ENV['TERRAGOV_REPO_DIR'])
      else
        return File.expand_path('.')
      end
    end

    def stack
      error_message = "Must set AWS stackname. Use --help for details"

      if $stack
        return $stack
      elsif ENV['TERRAGOV_STACKNAME']
        return ENV['TERRAGOV_STACKNAME']
      else
        abort(error_message)
      end
    end

    def extra
      return $extra if $extra
    end

    def cmd_options
      cmd_options_hash = {
        "environment" => env,
        "data_dir"    => data_dir,
        "project"     => project,
        "stack"       => stack,
        "repo_dir"    => repo_dir,
        "extra"       => extra,
      }
      return cmd_options_hash
    end

    def run
      command :plan do |c|
        c.syntax = 'terragov plan'
        c.description = 'Runs a plan of your code'
        c.action do |args, options|
          if options.verbose
            ENV['TERRAGOV_VERBOSE'] = "true"
            puts "Running plan"
            puts cmd_options.to_yaml
          end

          paths = Terragov::BuildPaths.new.base(cmd_options)
          varfiles = Terragov::BuildPaths.new.build_command(cmd_options)
          backend  = paths[:backend_file]
          project_dir = paths[:project_dir]
          Terragov::Terraform.new.execute('plan', varfiles, backend, project_dir)

        end
      end

      command :apply do |c|
        c.syntax = 'terragov apply'
        c.description = 'Apply your code'
        c.action do |args, options|
          if options.verbose
            puts "Running apply"
            puts cmd_options.to_yaml
          end
        end
      end

      command :destroy do |c|
        c.syntax = 'terragov destroy'
        c.description = 'Destroy your selected project'
        c.action do |args, options|
          puts "destroy"
        end
      end

      command :clean do |c|
        c.syntax = 'terragov clean'
        c.description = 'Clean your directory of any files terraform may have left lying around'
        c.action do |args, options|
          puts "clean"
        end
      end

      run!
    end
  end
end
