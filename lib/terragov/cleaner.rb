require 'find'
require 'highline'

module Terragov
  class Cleaner
    def delete(path, pattern, force=false)
      cli = HighLine.new

      files = Find.find(path).grep(pattern)

      if files.empty?
        puts "No files found matching #{pattern} in #{path}"
        exit
      end

      puts "Files matching #{pattern} found:"

      files.each do |file|
        puts File.expand_path(file)
      end

      unless force
        exit unless HighLine.agree('Do you wish to delete?')
      end

      files.each do |file|
        File.delete(File.expand_path(file))
      end
      puts "Done"
    end
  end
end
