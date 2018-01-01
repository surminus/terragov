require 'commander'
require 'yaml'
require 'highline'
require_relative 'buildpaths'
require_relative 'terraform'
require_relative 'cleaner'
require_relative 'version'
require_relative 'git'

module Terragov
  class Cli
    include Commander::Methods

    def initialize
      program :name, 'terragov'
      program :version, Terragov::VERSION
      program :description, 'Wrapper for GOV.UK Terraform deployments.'

      global_option('-c', '--config-file FILE', 'Specify a config file. Has less precedence than environment variables, which in turn have less precedence than CLI options') do |config_file|
        $config_file = config_file
      end

      global_option('-d', '--data-dir DIRECTORY', String, 'Location of the data directory') do |data_dir|
        $data_dir = data_dir
      end

      global_option('-e', '--environment STRING', String, 'Select environment') do |environment|
        $environment = environment
      end

      global_option('-p', '--project STRING', String, 'Name of the project') do |project|
        $project = project
      end

      global_option('-r', '--repo-dir DIRECTORY', String, 'Location of the main terraform repository') do |repo_dir|
        $repo_dir = repo_dir
      end

      global_option('-s', '--stack STRING', String, 'Name of the stack') do |stack|
        $stack = stack
      end

      global_option('--extra STRING', String, 'Any additional arguments to pass in the following format: --extra \\\\-target resource.foo.') do |extra|
        $extra = extra
      end

      global_option('--verbose', 'Verbose mode') do |verbose|
        $verbose = verbose
      end

      global_option('--dry-run', 'Dry run mode', 'Output the commands to run, but do not run them') do |dryrun|
        $dryrun = dryrun
      end

      global_option('--skip-git-check', 'Skip git check', 'Do not check the status of git repositories') do |skip_git_check|
        $skip_git_check = skip_git_check
      end
    end

    def data_dir
      $data_dir ? $data_dir : false
    end

    def environment
      $environment ? $environment : false
    end

    def project
      $project ? $project : false
    end

    def repo_dir
      $repo_dir ? $repo_dir : false
    end

    def stack
      $stack ? $stack : false
    end

    def extra
      return $extra if $extra
    end

    def verbose
      true ? $verbose : false
    end

    def dryrun
      true ? $dryrun : false
    end

    def skip_git_check
      true ? $skip_git_check : false
    end

    def load_config_file
      if $config_file || ENV['TERRAGOV_CONFIG_FILE']
        file = $config_file || ENV['TERRAGOV_CONFIG_FILE']
        YAML.load_file(File.expand_path(file))
      end
    end

    def config_file_default
      if load_config_file['default'].nil?
        return nil
      else
        return load_config_file['default']
      end
    end

    def config_file_specific_project(project_name)
      load_config_file[project_name]
    end

    def config_file(option)
      # This has to be loaded in seperately to avoid any cyclic dependencies
      project_name = $project || ENV['TERRAGOV_PROJECT']

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

    def config(option, file = false, required = true)
      env_var = "TERRAGOV_#{option.upcase}"
      error_message = "Must set #{option}. Use --help for details."

      # Load from CLI option
      if public_send(option)
        if file
          return File.expand_path(public_send(option))
        else
          return public_send(option)
        end

      # Load from environment variable
      elsif ENV[env_var]
        if file
          return File.expand_path(ENV[env_var])
        else
          return ENV[env_var]
        end

      # Load from config file
      elsif !load_config_file.nil?
        if config_file(option).nil?
          abort(error_message) if required
          return false
        else
          if file
            return File.expand_path(config_file(option))
          else
            return config_file(option)
          end
        end
      else
        abort(error_message) if required
        return false
      end
    end

    def cmd_options(deployment = false)
      cmd_hash = {}

      # Always load the project name first
      unless deployment
        cmd_hash = { 'project' => config('project') }
      end

      cmd_hash.merge({
        'environment' => config('environment'),
        'data_dir'    => config('data_dir', true),
        'stack'       => config('stack'),
        'repo_dir'    => config('repo_dir', true),
        'extra'       => extra
      })
    end

    def git_compare_repo_and_data(skip = false)
      git_helper = Terragov::Git.new
      # FIXME: this is confusing as we want to check the repository git status from
      # the root, but the "data" directory is one level down in the repository
      repo_dir_root = cmd_options['repo_dir']
      data_dir_root = File.expand_path(File.join(cmd_options['data_dir'], '../'))

      repo_dir_branch = git_helper.branch_name(repo_dir_root)
      data_dir_branch = git_helper.branch_name(data_dir_root)

      branches = {
        'repo_dir' => repo_dir_branch,
        'data_dir' => data_dir_branch
      }

      unless skip
        branches.each do |name, branch|
          unless branch =~ /^master$/
            exit unless HighLine.agree("#{name} not on 'master' branch, continue on branch '#{branch}'?")
          end
        end

        unless git_helper.compare_branch(repo_dir_root, data_dir_root)
          puts "Warning: repo_dir(#{repo_dir_branch}) and data_dir(#{data_dir_branch}) on different branches"
          exit unless HighLine.agree('Do you wish to continue?')
        end
      end
    end

    def run_terraform_cmd(cmd, opt = nil, deployment = false)
      paths = Terragov::BuildPaths.new.base(cmd_options)
      varfiles = Terragov::BuildPaths.new.build_command(cmd_options)
      backend  = paths[:backend_file]
      project_dir = paths[:project_dir]

      options = Hash.new
      %w[verbose dryrun].each do |opts|
        options[opts] = config(opts, false, false)
      end

      unless deployment
        skip_check = config('skip_git_check', false, false)
        git_compare_repo_and_data(skip_check)
      end

      puts cmd_options.to_yaml if options['verbose']

      cmd = "#{cmd} #{opt}" if opt
      Terragov::Terraform.new.execute(cmd, varfiles, backend, project_dir, options)
    end

    def run_deployment(file, group, command, force)
      abort("Must set deployment file: --file") unless file
      abort("Must set command to run: --command") unless command
      abort("Cannot find deployment file: #{file}") unless File.exist?(file)

      deployment_file = YAML.load_file(File.expand_path(file))
      deployment_config = deployment_file[group]

      if deployment_config.nil?
        abort("Deployment configuration must be an array of projects to run")
      end

      if command == 'plan' || command == 'apply'
        if force && command == 'apply'
          command = "#{command} -auto-approve"
        end

        deployment_config.each do |proj|
          $project = proj
          run_terraform_cmd(command, nil, true)
        end
      elsif command == 'destroy'
        if force
          command = "#{command} -force"
        end

        deployment_config.reverse.each do |proj|
          $project = proj
          run_terraform_cmd(command, nil, true)
        end
      else
        abort("Command must be apply, plan or destroy")
      end
    end

    def run
      command :plan do |c|
        c.syntax = 'terragov plan'
        c.description = 'Runs a plan of your code'
        c.action do |_args, options|
          run_terraform_cmd(c.name)
        end
      end

      command :apply do |c|
        c.syntax = 'terragov apply'
        c.description = 'Apply your code'
        c.option '--force', 'Force apply'
        c.action do |_args, options|
          if options.force
            run_terraform_cmd("#{c.name} -auto-approve")
          else
            run_terraform_cmd(c.name)
          end
        end
      end

      command :destroy do |c|
        c.syntax = 'terragov destroy'
        c.description = 'Destroy your selected project'
        c.option '--force', 'Force destroy'
        c.action do |_args, options|
          if options.force
            run_terraform_cmd("#{c.name} -force")
          else
            run_terraform_cmd(c.name)
          end
        end
      end

      command :deploy do |c|
        c.syntax = 'terragov deploy -f <deployment file>'
        c.description = 'Deploy a group of projects as specified in a deployment configuration'
        c.option '-f', '--file STRING', 'Specify deployment file'
        c.option '-g', '--group STRING', 'Specify group that you wish to deploy'
        c.option '-c', '--command STRING', 'What command to run: apply, plan or destroy.'
        c.option '--force', 'Force apply or destroy'
        c.action do |_args, options|

          group = options.group.nil? ? 'default' : options.group

          run_deployment(options.file, group, options.command, options.force)
        end
      end

      command :clean do |c|
        c.syntax = 'terragov clean'
        c.description = 'Clean your directory of any files terraform may have left lying around'
        c.option '--force', 'Force removal of files'
        c.action do |_args, options|
          if config('verbose', false, false)
            puts "Selecting directory #{repo_dir}"
          end

          files_to_delete = [
            /\.terraform$/,
            /terraform\.tfstate\.backup/,
          ]

          path = config('repo_dir', true)

          Terragov::Cleaner.new.delete(path, files_to_delete, options.force)
        end
      end

      run!
    end
  end
end
