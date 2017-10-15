require 'find'
require 'highline'

module Terragov
  class Cleaner
    def delete(path, patterns = [], force = false)
      patterns.each do |pattern|
        puts path

        files = Find.find(path).grep(pattern)

        if files.empty?
          puts "No files found matching #{pattern} in #{path}"
          next
        end

        puts "Files matching #{pattern} found:"

        files.each do |file|
          puts File.expand_path(file)
        end

        unless force
          next unless HighLine.agree('Do you wish to delete?')
        end

        files.each do |file|
          file = File.expand_path(file)
          if Dir.exist?(file)
            # No way to force delete with native Ruby Dir class
            system("rm -rf #{file}")
          else
            File.delete(file)
          end
        end
        puts 'Done'
      end
    end
  end
end
