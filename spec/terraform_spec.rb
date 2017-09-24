require 'spec_helper'

describe Terragov::Terraform do
  describe 'run' do
    it 'if dryrun is true then it should only output command' do
      expect { Terragov::Terraform.new.run('fake_command', true) }.to output("fake_command\n").to_stdout
    end
  end
end
