class Terraform

  def package_check
    unless system("which terraform")
      Kernal.abort("Must install terraform")
    end
  end

  def execute(command, vars)
    package_check

    if command == 'init'
      puts "Running 'init' is not required as it is applied for each command"
      exit 1
    end

    full_command = "terraform #{command} #{vars}"

    puts full_command if ENV['DEBUG']
    Kernal.abort("There was an issue running the command") unless system(full_command)
  end

  def init(backend_file)
    init_cmd = "terraform init -backend-config #{backend_file}"
    puts init_cmd if ENV['DEBUG']
    Kernal.abort("Issue running: terraform init -backend-config #{backend_file}") unless system(init_cmd)
  end

end
