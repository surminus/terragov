require 'commander'
require 'yaml'
require 'highline'
require_relative 'buildpaths'
require_relative 'terraform'
require_relative 'cleaner'
require_relative 'version'
require_relative 'git'
require_relative 'config'

module Terragov
  class Cli
    include Commander::Methods

    def initialize
      program :name, 'terragov'
      program :version, Terragov::VERSION
      program :description, 'Wrapper for GOV.UK Terraform deployments.'

      # Project should be loaded independently, unless used in deployment mode
      global_option('-p', '--project STRING', String, 'Name of the project') do |project|
        $project = project || ENV['TERRAGOV_PROJECT']
      end

      global_option('-c', '--config-file FILE', 'Specify a config file. Has less precedence than environment variables, which in turn have less precedence than CLI options') do |config_file|
        $config_file = config_file || ENV['TERRAGOV_CONFIG_FILE']
      end

      global_option('-d', '--data-dir DIRECTORY', String, 'Location of the data directory') do |data_dir|
       @data_dir_cli ||= data_dir
      end

      global_option('-e', '--environment STRING', String, 'Select environment') do |environment|
        @environment_cli = environment || false
      end

      global_option('-r', '--repo-dir DIRECTORY', String, 'Location of the main terraform repository') do |repo_dir|
        @repo_dir_cli = repo_dir || false
      end

      global_option('-s', '--stack STRING', String, 'Name of the stack') do |stack|
        @stack_cli = stack || false
      end

      global_option('--extra STRING', String, 'Any additional arguments to pass in the following format: --extra \\\\-target resource.foo.') do |extra|
        @extra = extra || nil
      end

      global_option('--verbose', 'Verbose mode') do |verbose|
        @verbose = verbose || false
      end

      global_option('--dry-run', 'Dry run mode', 'Output the commands to run, but do not run them') do |dryrun|
        @dryrun = dryrun || false
      end

      global_option('--skip-git-check', 'Skip git check', 'Do not check the status of git repositories') do |skip_git_check|
        @skip_git_check = skip_git_check || false
      end
    end

    def cmd_options(deployment = false)
      cmd_hash = {}

      # Always load the project name first
      unless deployment
        cmd_hash = { 'project' => $project }
      end

      config = Terragov::Config.new

      data_dir = config.lookup({
        name: 'data_dir',
        cli: @data_dir_cli,
        file: true,
      })
      environment = config.lookup({
        name: 'environment',
        cli: @environment_cli,
      })
      repo_dir = config.lookup({
        name: 'repo_dir',
        cli: @repo_dir_cli,
        file: true,
      })
      stack = config.lookup({
        name: 'stack',
        cli: @stack_cli,
      })

      #require 'pry'; binding.pry

      cmd_hash.merge({
        'environment' => environment,
        'data_dir'    => data_dir,
        'stack'       => stack,
        'repo_dir'    => repo_dir,
        'extra'       => @extra,
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

      be_verbose = Terragov::Config.new.lookup({name: 'verbose', required: false, cli: @verbose})

      do_dryrun = Terragov::Config.new.lookup({name: 'dryrun', required: false, cli: @dryrun})

      unless deployment
        skip_check = Terragov::Config.new.lookup({name: 'skip_git_check', required: false, cli: @skip_git_check})
        git_compare_repo_and_data(skip_check)
      end

      puts cmd_options.to_yaml if be_verbose

      cmd = "#{cmd} #{opt}" if opt
      Terragov::Terraform.new.execute(cmd, varfiles, backend, project_dir, do_dryrun, be_verbose)
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
          if Terragov::Config.new.lookup({name: 'verbose', required: false, cli: @verbose})
            puts "Selecting directory #{repo_dir}"
          end

          files_to_delete = [
            /\.terraform$/,
            /terraform\.tfstate\.backup/,
          ]

          path = Terragov::Config.new.lookup({name: 'repo_dir', file: true})

          Terragov::Cleaner.new.delete(path, files_to_delete, options.force)
        end
      end

      run!
    end
  end
end
