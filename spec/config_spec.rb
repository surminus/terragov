require 'spec_helper'

describe Terragov::Config do
  describe 'load_config_file' do
    mock_hash = {
      'default' => {
        'environment' => 'dev',
        'stack'       => 'mystack',
        'repo_dir'    => 'spec/stub',
        'data_dir'    => 'spec/stub/data'
      },
      'app-fake' => {
        'stack' => 'apples'
      }
    }
    it 'It returns a hash of values when defined from an env var' do
      ENV['TERRAGOV_CONFIG_FILE'] = 'spec/stub/myconfig.yml'
      config = Terragov::Config.new.load_config_file
      expect(config).to include(mock_hash)
      ENV['TERRAGOV_CONFIG_FILE'] = nil
    end

    it 'It returns a hash of values when defined by CLI option' do
      $config_file = 'spec/stub/myconfig.yml'
      config = Terragov::Config.new.load_config_file
      expect(config).to include(mock_hash)
      $config_file = nil
    end
  end

  describe 'lookup' do
    it 'if set from CLI options, it should return correct value' do
      hash = { name: 'stack', cli: 'mystack' }
      expect(Terragov::Config.new.lookup(hash)).to eq('mystack')
      $stack = nil
    end

    it 'if set from CLI options and is a file, it should return correct value' do
      hash = {
        name: 'repo_dir',
        cli: 'spec/stub',
        file: true,
      }
      expected = File.expand_path('spec/stub')
      expect(Terragov::Config.new.lookup(hash)).to eq(expected)
    end

    it 'if set from environment variable options, it should return correct value' do
      hash = {
        name: 'stack',
      }
      ENV['TERRAGOV_STACK'] = 'mystack'
      expect(Terragov::Config.new.lookup(hash)).to eq('mystack')
      ENV['TERRAGOV_STACK'] = nil
    end

    context 'if config file specified' do
      it 'if value exists within config file under default, return correct value' do
        hash = { name: 'stack' }
        ENV['TERRAGOV_CONFIG_FILE'] = 'spec/stub/myconfig.yml'
        expect(Terragov::Config.new.lookup(hash)).to eq('mystack')
        ENV['TERRAGOV_CONFIG_FILE'] = nil
      end

      it 'if value exists within config file under specified project, return correct value' do
        hash = { name: 'stack' }
        ENV['TERRAGOV_PROJECT'] = 'app-fake'
        ENV['TERRAGOV_CONFIG_FILE'] = 'spec/stub/myconfig.yml'
        expect(Terragov::Config.new.lookup(hash)).to eq('apples')
        ENV['TERRAGOV_CONFIG_FILE'] = nil
        ENV['TERRAGOV_PROJECT'] = nil
      end

      it 'if app specific config available, but nothing for specific value, return default' do
        hash = { name: 'environment' }
        ENV['TERRAGOV_PROJECT'] = 'app-fake'
        ENV['TERRAGOV_CONFIG_FILE'] = 'spec/stub/myconfig.yml'
        expect(Terragov::Config.new.lookup(hash)).to eq('dev')
        ENV['TERRAGOV_CONFIG_FILE'] = nil
        ENV['TERRAGOV_PROJECT'] = nil
      end

      it 'if no expected value exists within config file, abort' do
        hash = { name: 'stack' }
        ENV['TERRAGOV_CONFIG_FILE'] = 'spec/stub/badconfig.yml'
        expect { Terragov::Config.new.lookup(hash) }.to raise_error('Must set stack. Use --help for details.')
        ENV['TERRAGOV_CONFIG_FILE'] = nil
      end

      it 'if no expected value exists within config file, but is not required, do not abort but return false' do
        hash = { name: 'stack', required: false }
        ENV['TERRAGOV_CONFIG_FILE'] = 'spec/stub/badconfig.yml'
        expect { Terragov::Config.new.lookup(hash) }.to_not raise_error
        expect(Terragov::Config.new.lookup(hash)).to be false
        ENV['TERRAGOV_CONFIG_FILE'] = nil
      end
    end

    it 'if no CLI option, env var or config file set, abort' do
      hash = { name: 'stack' }
      expect { Terragov::Config.new.lookup(hash) }.to raise_error('Must set stack. Use --help for details.')
    end
  end
end
