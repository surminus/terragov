# frozen_string_literal: true

require 'english'

module Terragov
  # A set of methods for everything related to running
  # Terraform in system
  class Terraform
    def package_check(package)
      return if system("which #{package} >/dev/null")

      unless HighLine.agree("Can't find #{package}. Install using Homebrew?")
        abort("Must install #{package}")
      end

      if system('which brew >/dev/null')
        system("brew install #{package}")
      else
        abort('Error: cannot find brew')
      end
    end

    def check_for_packages(packages = [])
      packages.each do |pkg|
        package_check(pkg)
      end
    end

    def execute(command, vars, backend, directory, options = {})
      check_for_packages(%w[terraform sops])

      current_dir = Dir.pwd

      Dir.chdir directory
      init(backend, options)

      command == 'plan' && command = 'plan -detailed-exitcode'

      full_command = "bash -c 'terraform #{command} #{vars}'"

      run(full_command, options)

      Dir.chdir current_dir
    end

    def init(backend_file, options = {})
      init_cmd = "terraform init -backend-config #{backend_file}"
      run(init_cmd, options)
    end

    def exit_check
      # Catch the output of "-detailed-exitcode"
      if $CHILD_STATUS == 2
        puts [
          'Command completed successfully',
          'but with updates available to apply'
        ].join(' ')
        exit 2
      elsif $CHILD_STATUS != (0 || 2)
        abort("There was an issue running command: #{command}")
      end
    end

    def run(command, options = {})
      return puts command if options['dryrun']

      puts command if options['verbose']
      system(command)

      exit_check
    end
  end
end
