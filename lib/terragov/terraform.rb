module Terragov
  class Terraform

    def package_check
      unless system("which terraform >/dev/null")
        abort("Must install terraform")
      end

      unless system("which sops >/dev/null")
        abort("Must install sops")
      end
    end

    def execute(command, vars, backend, directory, dryrun=false, verbose=false)
      package_check

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
