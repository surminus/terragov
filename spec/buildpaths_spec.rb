require "spec_helper"

if ENV['TRAVIS_BUILD_DIR']
  curdir = ENV['TRAVIS_BUILD_DIR']
else
  curdir = File.expand_path('.')
end



describe Terragov::BuildPaths do
  options = {
    'environment' => 'dev',
    'data_dir'    => "#{curdir}/spec/mocks/data",
    'repo_dir'    => "#{curdir}/spec/mocks",
    'stack'       => 'mystack',
    'project'     => 'myproject',
    'extra'       => '',
  }
  describe "base" do
    it "Takes options in a hash format and produces a hash of paths" do
      base_paths = Terragov::BuildPaths.new.base(options)
      expect(base_paths).to include(
        :terraform_dir              => "#{curdir}/spec/mocks/terraform",
        :project_dir                => "#{curdir}/spec/mocks/terraform/projects/myproject",
        :common_data_dir            => "#{curdir}/spec/mocks/data/common/dev",
        :common_data                => "#{curdir}/spec/mocks/data/common/dev/common.tfvars",
        :stack_common_data          => "#{curdir}/spec/mocks/data/common/dev/mystack.tfvars",
        :project_data_dir           => "#{curdir}/spec/mocks/data/myproject/dev",
        :common_project_data        => "#{curdir}/spec/mocks/data/myproject/dev/common.tfvars",
        :secret_common_project_data => "#{curdir}/spec/mocks/data/myproject/dev/common.secret.tfvars",
        :stack_project_data         => "#{curdir}/spec/mocks/data/myproject/dev/mystack.tfvars",
        :secret_project_data        => "#{curdir}/spec/mocks/data/myproject/dev/mystack.secret.tfvars",
      )
    end
  end

  let(:common_data_file){ "#{curdir}/spec/mocks/data/common/dev/common.tfvars" }

  describe "data_validation" do
    it "by default returns true if file or directory exist" do
      expect(Terragov::BuildPaths.new.data_validation(common_data_file)).to be true
    end

    it "returns false if the file or directory does not exist" do
      expect(Terragov::BuildPaths.new.data_validation('/path/to/some/fake/file')).to be false
    end

    it "if required set to true, return true if file exists" do
      expect(Terragov::BuildPaths.new.data_validation(common_data_file)).to be true
    end
  end

  describe "data_paths" do
    it "takes a hash and returns array of paths" do
      expect(Terragov::BuildPaths.new.data_paths(options)).to include(
        "#{curdir}/spec/mocks/data/common/dev/common.tfvars",
        "#{curdir}/spec/mocks/data/common/dev/mystack.tfvars",
        "#{curdir}/spec/mocks/data/myproject/dev/common.tfvars",
        "#{curdir}/spec/mocks/data/myproject/dev/common.secret.tfvars",
        "#{curdir}/spec/mocks/data/myproject/dev/mystack.tfvars",
        "#{curdir}/spec/mocks/data/myproject/dev/mystack.secret.tfvars",
      )
    end
  end

  real_var_files = [
   "#{curdir}/spec/mocks/data/common/dev/common.tfvars",
   "#{curdir}/spec/mocks/data/common/dev/mystack.tfvars",
   "#{curdir}/some/fake/file.foo",
  ]

  fake_var_files = [
    'some/file',
    'another/fake/file',
    'my/super/fake/file',
  ]

  describe "check_var_files" do
    it "takes an array of paths and if at least one exists, return true" do
      expect(Terragov::BuildPaths.new.check_var_files(real_var_files)).to be true
    end

    it "takes an array of paths and if none exist, return false" do
      expect(Terragov::BuildPaths.new.check_var_files(fake_var_files)).to be false
    end
  end

  describe "build_command" do
    it "takes a hash of options and constructs a terraform command" do
      expect(Terragov::BuildPaths.new.build_command(options)).to eq("-var-file #{curdir}/spec/mocks/data/common/dev/common.tfvars -var-file #{curdir}/spec/mocks/data/common/dev/mystack.tfvars -var-file #{curdir}/spec/mocks/data/myproject/dev/common.tfvars -var-file <(sops -d #{curdir}/spec/mocks/data/myproject/dev/common.secret.tfvars) -var-file #{curdir}/spec/mocks/data/myproject/dev/mystack.tfvars -var-file <(sops -d #{curdir}/spec/mocks/data/myproject/dev/mystack.secret.tfvars) ")
    end

    it "if extra option is defined then append to command" do
      options["extra"] = "\\-target resource.foo"

      expect(Terragov::BuildPaths.new.build_command(options)).to eq("-var-file #{curdir}/spec/mocks/data/common/dev/common.tfvars -var-file #{curdir}/spec/mocks/data/common/dev/mystack.tfvars -var-file #{curdir}/spec/mocks/data/myproject/dev/common.tfvars -var-file <(sops -d #{curdir}/spec/mocks/data/myproject/dev/common.secret.tfvars) -var-file #{curdir}/spec/mocks/data/myproject/dev/mystack.tfvars -var-file <(sops -d #{curdir}/spec/mocks/data/myproject/dev/mystack.secret.tfvars) -target resource.foo")
    end

  end
end
