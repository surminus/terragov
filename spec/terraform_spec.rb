require 'spec_helper'

describe Terragov::Terraform do
  terraform = Terragov::Terraform.new
  describe 'run' do
    it 'if dryrun is true then it should only output command' do
      expect { terraform.run('fake_command', true) }.to output("fake_command\n").to_stdout
    end
  end

  describe 'execute' do
    args = {
      command: 'apply',
      dryrun: true,
      directory: 'test/dir',
      backend: 'some/backend/file.backend',
      vars: '-var-file data/dir/something.tfvars',
      verbose: false,
    }
    it 'should call the #run method' do
      expect(terraform).to receive(:run).with("terraform init -backend-config #{args[:backend]}", args[:dryrun], args[:verbose])
      expect(terraform).to receive(:run).with("bash -c 'terraform #{args[:command]} #{args[:vars]}'", args[:dryrun], args[:verbose])
      terraform.execute(args)
    end
  end
  describe 'init' do
    it 'should call the #run method' do
      expect(terraform).to receive(:run).with('terraform init -backend-config foo.backend', true, false)
      terraform.init('foo.backend', true, false)
    end
  end
end
