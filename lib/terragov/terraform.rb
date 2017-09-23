module Terragov
  class Terraform

    def package_check(package)
      unless system("which #{package} >/dev/null")
        abort("Must install #{package}") unless HighLine.agree("Can't find #{package}. Install using Homebrew?")
        if system("which brew >/dev/null")
          system("brew install #{package}")
        else
          abort("Error: cannot find brew")
        end
      end
    end

    def execute(command, vars, backend, directory, dryrun=false, verbose=false)
      packages = [ 'terraform', 'sops' ]

      packages.each do |pkg|
        package_check(pkg)
      end

      if command == 'init'
        puts "Running 'init' is not required as it is applied for each command"
        exit 1
      end

      Dir.chdir directory
      init(backend, dryrun, verbose)

      full_command = "bash -c 'terraform #{command} #{vars}'"

      if dryrun
        puts full_command
      else
        puts "#{command} command: #{full_command}" if verbose
        abort("There was an issue running the command") unless system(full_command)
      end
    end

    def init(backend_file, dryrun=false, verbose=false)
      init_cmd = "terraform init -backend-config #{backend_file}"
      if dryrun
        puts init_cmd
      else
        puts "init command: #{init_cmd}" if verbose
        abort("Issue running: terraform init -backend-config #{backend_file}") unless system(init_cmd)
      end
    end

  end
end
