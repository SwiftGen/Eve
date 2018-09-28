#!/usr/bin/rake
require 'yaml'
require 'json'
require 'net/http'
require 'uri'
require 'plist'
require 'English'

namespace :repos do
  REPOS = %i[StencilSwiftKit SwiftGen].freeze
  desc 'Bootstrap this repository for development'
  task :bootstrap do
    REPOS.each do |repository|
      next if Dir.exist? repository.to_s

      sh "git clone git@github.com:SwiftGen/#{repository}.git --recursive"
    end
  end

  def each_repo
    REPOS.each do |repo|
      Dir.chdir(repo.to_s) do
        Utils.print_header "=== #{repo} ==="
        yield
      end
    end
  end

  desc 'Print status of each repo'
  task :status do
    each_repo { puts `git status` }
  end

  desc 'git pull each repo'
  task :pull do
    each_repo { puts `git pull` }
  end

  desc 'git checkout master each repo'
  task :master do
    each_repo { puts `git checkout master` }
  end
end
