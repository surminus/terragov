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

    def execute(command, vars, backend, directory, dryrun = false, verbose = false)
      packages = %w[terraform sops]

      packages.each do |pkg|
        package_check(pkg)
      end

      if command == 'init'
        puts "Running 'init' is not required as it is applied for each command"
        exit 1
      end

      current_dir = Dir.pwd

      Dir.chdir directory
      init(backend, dryrun, verbose)

      if command == 'plan'
        command = 'plan -detailed-exitcode'
      end

      full_command = "bash -c 'terraform #{command} #{vars}'"

      run(full_command, dryrun, verbose)

      Dir.chdir current_dir
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
