require 'spec_helper'

describe Terragov::Cleaner do
  describe 'delete' do
    path = File.expand_path('spec/stub')
    pattern = [/foo\.txt/]
    test_file = File.join(path, 'foo.txt')

    it 'should move on if no matching files found' do
      expect { Terragov::Cleaner.new.delete(path, ['some_fake_pattern'], true) }.to_not raise_error
    end

    it 'should delete files matching pattern in a given path (with force option)' do
      File.write(test_file, 'foo')
      expect { Terragov::Cleaner.new.delete(path, pattern, true) }.to output(/Done/).to_stdout
      expect(File.exist?(test_file)).to be false
    end
  end
end
