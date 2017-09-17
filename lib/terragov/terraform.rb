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

    def execute(command, vars, backend, directory)
      package_check

      if command == 'init'
        puts "Running 'init' is not required as it is applied for each command"
        exit 1
      end

      Dir.chdir directory
      init(backend)

      full_command = "bash -c 'terraform #{command} #{vars}'"

      if ENV['TERRAGOV_DRYRUN']
        puts full_command
      else
        puts "#{command} command: #{full_command}" if ENV['TERRAGOV_VERBOSE']
        abort("There was an issue running the command") unless system(full_command)
      end
    end

    def init(backend_file)
      init_cmd = "terraform init -backend-config #{backend_file}"
      if ENV['TERRAGOV_DRYRUN']
        puts init_cmd
      else
        puts "init command: #{init_cmd}" if ENV['TERRAGOV_VERBOSE']
        abort("Issue running: terraform init -backend-config #{backend_file}") unless system(init_cmd)
      end
    end

  end
end
