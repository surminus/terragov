require 'spec_helper'

describe Terragov::Cli do
  describe 'load_config_file' do
    mock_hash = {
      'environment' => 'foo',
      'stack'       => 'bar',
      'repo_dir'    => 'spec/stub',
      'data_dir'    => 'spec/stub/data'
    }
    it 'It returns a hash of values when defined from an env var' do
      ENV['TERRAGOV_CONFIG_FILE'] = 'spec/stub/myconfig.yml'
      config = Terragov::Cli.new.load_config_file
      expect(config).to include(mock_hash)
      ENV['TERRAGOV_CONFIG_FILE'] = nil
    end

    it 'It returns a hash of values when defined by CLI option' do
      $config_file = 'spec/stub/myconfig.yml'
      config = Terragov::Cli.new.load_config_file
      expect(config).to include(mock_hash)
      $config_file = nil
    end
  end

  describe 'config' do
    it 'if set from CLI options, it should return correct value' do
      $stack = 'mystack'
      expect(Terragov::Cli.new.config('stack')).to eq('mystack')
      $stack = nil
    end

    it 'if set from CLI options and is a file, it should return correct value' do
      $repo_dir = 'spec/stub'
      expected = File.expand_path($repo_dir)
      expect(Terragov::Cli.new.config('repo_dir', true)).to eq(expected)
      $repo_dir = nil
    end

    it 'if set from environment variable options, it should return correct value' do
      ENV['TERRAGOV_STACK'] = 'mystack'
      expect(Terragov::Cli.new.config('stack')).to eq('mystack')
      ENV['TERRAGOV_STACK'] = nil
    end

    context 'if config file specified' do
      it 'if value exists within config file, return correct value' do
        ENV['TERRAGOV_CONFIG_FILE'] = 'spec/stub/myconfig.yml'
        expect(Terragov::Cli.new.config('stack')).to eq('bar')
        ENV['TERRAGOV_CONFIG_FILE'] = nil
      end

      it 'if no expected value exists within config file, abort' do
        ENV['TERRAGOV_CONFIG_FILE'] = 'spec/stub/badconfig.yml'
        expect { Terragov::Cli.new.config('stack') }.to raise_error('Must set stack. Use --help for details.')
        ENV['TERRAGOV_CONFIG_FILE'] = nil
      end

      it 'if no expected value exists within config file, but is not required, do not abort but return false' do
        ENV['TERRAGOV_CONFIG_FILE'] = 'spec/stub/badconfig.yml'
        expect { Terragov::Cli.new.config('stack', false, false) }.to_not raise_error
        expect(Terragov::Cli.new.config('stack', false, false)).to be false
        ENV['TERRAGOV_CONFIG_FILE'] = nil
      end
    end

    it 'if no CLI option, env var or config file set, abort' do
      expect { Terragov::Cli.new.config('stack') }.to raise_error('Must set stack. Use --help for details.')
    end
  end
end
