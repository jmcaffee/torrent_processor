######################################################################################
# File:: rakefile
# Purpose:: Build tasks for TorrentProcessor application
#
# Author::    Jeff McAffee 07/31/2011
# Copyright:: Copyright (c) 2011, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
######################################################################################

require 'rubygems'
require 'psych'
gem 'rdoc', '>= 3.9.4'

require 'rake'
require 'rake/clean'
require 'rdoc/task'
require 'ostruct'
require 'rspec/core/rake_task'
require 'puck'
require_relative 'rakelib/lib/ext/string'


# Setup common directory structure


PROJNAME        = "TorrentProcessor"
BUILDDIR        = "./build"
DISTDIR         = "./dist"

$:.unshift File.expand_path("../lib", __FILE__)
require "torrent_processor/version"

PKG_VERSION = TorrentProcessor::VERSION
PKG_FILES   = Dir["**/*"].select { |d| d =~ %r{^(README|bin/|data/|ext/|lib/|spec/|test/)} }

# Setup common clean and clobber targets

CLEAN.include("#{BUILDDIR}/**/*.*")
CLOBBER.include("#{BUILDDIR}")
CLEAN.include("#{DISTDIR}/**/*.*")
CLOBBER.include("#{DISTDIR}/**/*.*")


directory BUILDDIR
directory DISTDIR



RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '-fp'
  #require 'pry'; binding.pry
end

RSpec::Core::RakeTask.new(:spec_pretty) do |t|
  t.rspec_opts = '-fd'
  #require 'pry'; binding.pry
end

task :default => [:spec]

desc "Build jar and scripts"
task :build => [BUILDDIR, :jar, 'script:generate_cmd', 'script:generate_sh', 'script:generate_install_sh', 'script:generate_uninstall_sh'] do
end

namespace :build do
  desc "Clean build dir"
  task :clean do
    rm_rf 'build'
  end

  task :drop do
    # If we don't expand the path, the `exist?` method doesn't find the path
    # even if it exists.
    dropdir = Pathname(Pathname("~/Dropbox/torrents").expand_path)
    if dropdir.exist?
      jarfile = "#{PROJNAME.snakecase}-#{PKG_VERSION}.jar"
      rm_f "#{dropdir}/#{jarfile}"
      cd './build' do
        sh "cp #{jarfile} #{dropdir}/"
      end
    else
      puts "[build:drop] dropdir doesn't exist: #{dropdir}"
    end
  end
end

task :jar do
  jar = Puck::Jar.new(
    app_name: "#{PROJNAME.snakecase}-#{PKG_VERSION}"
  )
  jar.create!
end

desc 'Build project and package for distribution'
task :dist => [:build, DISTDIR] do
  archive_name = "#{PROJNAME.snakecase}-#{PKG_VERSION}.7z"
  cd './build' do
    #files = Dir['*.*', '*.']
    files = Dir['*']

    result = `7z a ./#{archive_name} #{files.join(' ')}`
    puts result
  end

  mv "./build/#{archive_name}", './dist'
end

namespace :dist do
  desc "Clean dist dir"
  task :clean do
    rm_rf 'dist'
  end
end

#############################################################################
#task :init => [BUILDDIR] do
task :init => [BUILDDIR, DISTDIR] do

end


#############################################################################
RDoc::Task.new(:rdoc) do |rdoc|
    files = ['docs/**/*.rdoc', 'lib/**/*.rb', 'app/**/*.rb']
    rdoc.rdoc_files.add( files )
    rdoc.main = "docs/README.rdoc"            # Page to start on
  #puts "PWD: #{FileUtils.pwd}"
    rdoc.title = "#{PROJNAME} Documentation"
    rdoc.rdoc_dir = 'doc'                   # rdoc output folder
    rdoc.options << '--line-numbers' << '--all'
end


#############################################################################
desc "Run all tests"
task :test => [:init] do
  unless File.directory?('test')
    $stderr.puts 'no test in this package'
    return
  end
  $stderr.puts 'Running tests...'
  begin
    require 'test/unit'
  rescue LoadError
    $stderr.puts 'test/unit cannot loaded.  You need Ruby 1.8 or later to invoke this task.'
  end
  
  $LOAD_PATH.unshift("./")
  $LOAD_PATH.unshift(TESTDIR)
  Dir[File.join(TESTDIR, "*.rb")].each {|file| require File.basename(file) }
  require 'minitest/autorun'
end
