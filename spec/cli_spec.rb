require 'spec_helper'

# A series of end-to-end tests that ensures the validity of what we expect
# to output

describe Terragov::Cli do
  describe 'run' do
    describe 'plan' do
      default_command = %w(
        bin/terragov
        --dry-run
        --skip-git-check
        plan
      )

      default_init_output = [
        'terraform init -backend-config',
        "#{File.join(Dir.pwd, 'spec/stub/terraform/projects/myproject/dev.mystack.backend')}\n"
      ]
      default_plan_output = [
        "bash -c 'terraform plan -detailed-exitcode",
        "-var-file #{File.join(Dir.pwd, 'spec/stub/data/common/dev/common.tfvars')}",
        "-var-file #{File.join(Dir.pwd, 'spec/stub/data/common/dev/mystack.tfvars')}",
        "-var-file #{File.join(Dir.pwd, 'spec/stub/data/myproject/dev/common.tfvars')}",
        "-var-file <(sops -d #{File.join(Dir.pwd, 'spec/stub/data/myproject/dev/common.secret.tfvars')})",
        "-var-file #{File.join(Dir.pwd, 'spec/stub/data/myproject/dev/mystack.tfvars')}",
        "-var-file <(sops -d #{File.join(Dir.pwd, 'spec/stub/data/myproject/dev/mystack.secret.tfvars')}) '\n"
      ]

      it 'everything specified from CLI options' do
        command_options = [
          '-d spec/stub/data',
          '-r spec/stub',
          '-p myproject',
          '-s mystack',
          '-e dev',
        ]

        expected_output = default_init_output.join(" ") + default_plan_output.join(" ")
        command = default_command.join(" ") + " " + command_options.join(" ")
        expect {
          system(command)
        }.to output(expected_output).to_stdout_from_any_process
      end
      it 'everything specified from ENV VAR options' do
        ENV['TERRAGOV_DATA_DIR'] = 'spec/stub/data'
        ENV['TERRAGOV_REPO_DIR'] = 'spec/stub'
        ENV['TERRAGOV_STACK'] = 'mystack'
        ENV['TERRAGOV_ENVIRONMENT'] = 'dev'

        command_options = [
          '-p myproject',
        ]

        expected_output = default_init_output.join(" ") + default_plan_output.join(" ")
        command = default_command.join(" ") + " " + command_options.join(" ")
        expect {
          system(command)
        }.to output(expected_output).to_stdout_from_any_process

        ENV['TERRAGOV_DATA_DIR'] = nil
        ENV['TERRAGOV_REPO_DIR'] = nil
        ENV['TERRAGOV_STACK'] = nil
        ENV['TERRAGOV_ENVIRONMENT'] = nil
      end
      it 'everything specified from config file' do
        ENV['TERRAGOV_CONFIG_FILE'] = 'spec/stub/myconfig.yml'

        command_options = [
          '-p myproject',
        ]

        expected_output = default_init_output.join(" ") + default_plan_output.join(" ")
        command = default_command.join(" ") + " " + command_options.join(" ")
        expect {
          system(command)
        }.to output(expected_output).to_stdout_from_any_process

        ENV['TERRAGOV_CONFIG_FILE'] = nil
      end
    end
  end
end
