module Terragov
  class Terraform
    def package_check(package)
      unless system("which #{package} >/dev/null")
        abort("Must install #{package}") unless HighLine.agree("Can't find #{package}. Install using Homebrew?")
        if system('which brew >/dev/null')
          system("brew install #{package}")
        else
          abort('Error: cannot find brew')
        end
      end
    end

    def execute(_args = {})
      # Schema:
      # {
      # command: which command to run
      # dryrun: set to true for a dry run
      # verbose: set to true for more output
      # directory: main repository directory
      # backend: backend file
      # vars: data directory
      # }
      default = {
        dryrun: false,
        verbose: false,
      }

      args = default.merge(_args)

      packages = %w[terraform sops]

      unless args[:dryrun]
        packages.each do |pkg|
          package_check(pkg)
        end
      end

      if args[:command] == 'init'
        puts "Running 'init' is not required as it is applied for each command"
        exit 1
      end

      current_dir = Dir.pwd

      Dir.chdir args[:directory] unless args[:dryrun]
      init(args[:backend], args[:dryrun], args[:verbose])

      if args[:command] == 'plan'
        command = 'plan -detailed-exitcode'
      else
        command = args[:command]
      end

      full_command = "bash -c 'terraform #{command} #{args[:vars]}'"

      run(full_command, args[:dryrun], args[:verbose])

      Dir.chdir current_dir unless args[:dryrun]
    end

    def init(backend_file, dryrun = false, verbose = false)
      init_cmd = "terraform init -backend-config #{backend_file}"
      run(init_cmd, dryrun, verbose)
    end

    def run(command, dryrun = false, verbose = false)
      if dryrun
        puts command
      else
        puts command if verbose
        system(command)

        # Catch the output of "-detailed-exitcode"
        if $?.exitstatus == 2
          puts "Command completed successfully, but with updates available to apply"
          exit 2
        elsif $?.exitstatus != (0 or 2)
          abort("There was an issue running command: #{command}")
        end
      end
    end
  end
end
