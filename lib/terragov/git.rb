# frozen_string_literal: true

require 'git'
require 'highline'

module Terragov
  # The Git class allows you force interactive output based upon
  # the current branches in the repo and data directories.
  class Git
    def branch_name(directory)
      unless File.exist?(File.join(directory, '.git'))
        exit unless HighLine.agree(
          "#{directory} not a git repository, do you wish to continue?"
        )
      end

      branch = ::Git.open(directory).current_branch

      branch
    end

    def compare_branch(dir_a, dir_b)
      branch_name(dir_a) == branch_name(dir_b)
    end
  end
end
