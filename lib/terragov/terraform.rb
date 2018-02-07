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
      # test: set to true to output commands to run, used for testing
      # verbose: set to true for more output
      # directory: main repository directory
      # backend: backend file
      # vars: data directory
      # }
      default = {
        test: false,
        verbose: false,
      }

      args = default.merge(_args)

      packages = %w[terraform sops]

      unless args[:test]
        packages.each do |pkg|
          package_check(pkg)
        end
      end

      if args[:command] == 'init'
        puts "Running 'init' is not required as it is applied for each command"
        exit 1
      end

      current_dir = Dir.pwd

      Dir.chdir args[:directory] unless args[:test]
      init(args[:backend], args[:test], args[:verbose])

      if args[:command] == 'plan'
        command = 'plan -detailed-exitcode'
      else
        command = args[:command]
      end

      full_command = "bash -c 'terraform #{command} #{args[:vars]}'"

      run(full_command, args[:test], args[:verbose])

      Dir.chdir current_dir unless args[:test]
    end

    def init(backend_file, test = false, verbose = false)
      init_cmd = "terraform init -backend-config #{backend_file}"
      run(init_cmd, test, verbose)
    end

    def run(command, test = false, verbose = false)
      if test
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
