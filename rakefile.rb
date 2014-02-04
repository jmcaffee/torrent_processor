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
require 'rakeUtils'
require 'rspec/core/rake_task'

# Setup common directory structure


PROJNAME        = "TorrentProcessor"
BUILDDIR        = "build"
DISTDIR         = "./dist"

$:.unshift File.expand_path("../lib", __FILE__)
require "torrentprocessor/version"

PKG_VERSION = TorrentProcessor::VERSION
PKG_FILES   = Dir["**/*"].select { |d| d =~ %r{^(README|bin/|data/|ext/|lib/|spec/|test/)} }

# Setup common clean and clobber targets

CLEAN.include("pkg")
CLOBBER.include("pkg")
CLEAN.include("#{BUILDDIR}/**/*.*")
CLOBBER.include("#{BUILDDIR}")
CLEAN.include("#{DISTDIR}/**/*.*")
CLOBBER.include("#{DISTDIR}/**/*.*")


directory BUILDDIR
directory DISTDIR


#############################################################################
#### Imports
# Note: Rake loads imports only after the current rakefile has been completely loaded.

# Load local tasks.
imports = FileList['tasks/**/*.rake']
imports.each do |imp|
  puts "== Importing local task file: #{imp}" if $verbose
  import "#{imp}"
end



RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '-fp'
  #require 'pry'; binding.pry
end

RSpec::Core::RakeTask.new(:spec_pretty) do |t|
  t.rspec_opts = '-fd'
  #require 'pry'; binding.pry
end

task :default => [:spec]


desc "Install gem and build installer"
task :dist => [:clean, :gem, :purge_gem_versions, :install_gem, :exe_installer]

task :purge_gem_versions do
  sh("gem uninstall #{PROJNAME.downcase} --all --executables")
end

task :install_gem do
  sh("gem install pkg/torrentprocessor-#{PKG_VERSION}.gem -l --no-document")
end

#############################################################################
#task :init => [BUILDDIR] do
task :init => [BUILDDIR, DISTDIR] do

end


#############################################################################
desc "Build a OCRA executable"
task :exe => [:init] do
  if (!File.exists?("#{BUILDDIR}/#{PROJNAME}.exe"))
      puts "*** Generating executable #{PROJNAME}.exe"
      REAL_LOCATION = File.absolute_path(".")
      puts "REAL_LOCATION: #{REAL_LOCATION}"
      cp("./bin/#{PROJNAME}", "#{BUILDDIR}/#{PROJNAME}.rb")
      cd("#{REAL_LOCATION}") do |d|
        # Using --no-lzma will turn off lzma compression. This may reduce application start up time:
        #   From http://rubyforge.org/pipermail/wxruby-users/2009-September.txt :
        #     Try building the executable with the --no-lzma option. The resulting 
        #     file will be bigger but it may well start faster. LZMA is a very 
        #     efficient compression algorithm but quite slow.

        # TODO: Test with no lzma and see if the start up time improves.

        output = `ocra --console #{BUILDDIR}/#{PROJNAME}.rb --no-lzma --gemfile gemfile`
        puts output
      end
  end
  
  mv("./#{PROJNAME}.exe", "#{BUILDDIR}/#{PROJNAME}.exe")
end


#############################################################################
desc "Build a OCRA executable with installer"
task :exe_installer => [:init, "inno:generate_iss"] do
  if (!File.exists?("#{BUILDDIR}/#{PROJNAME}Installer_#{PKG_VERSION}.exe"))
      puts "*** Generating executable #{PROJNAME}Installer_#{PKG_VERSION}.exe"
      REAL_LOCATION = File.absolute_path(".")
      puts "REAL_LOCATION: #{REAL_LOCATION}"
      cp("./bin/#{PROJNAME}", "#{BUILDDIR}/#{PROJNAME}.rb")
      cd("#{REAL_LOCATION}") do |d|
        # Using --no-lzma will turn off lzma compression. This may reduce application start up time:
        #   From http://rubyforge.org/pipermail/wxruby-users/2009-September.txt :
        #     Try building the executable with the --no-lzma option. The resulting 
        #     file will be bigger but it may well start faster. LZMA is a very 
        #     efficient compression algorithm but quite slow.

        # TODO: Test with no lzma and see if the start up time improves.

        output = `ocra --console #{BUILDDIR}/#{PROJNAME}.rb --chdir-first --no-lzma --gemfile gemfile --innosetup #{PROJNAME}.iss`
        puts output
      end
  end
  
  mv("./Output/#{PROJNAME}Installer_#{PKG_VERSION}.exe", "#{BUILDDIR}/#{PROJNAME}Installer_#{PKG_VERSION}.exe")
  rm_rf "./Output" if File.exists? './Output'
end


#############################################################################
desc "Documentation for building gem and executable"
task :help do
  hr = "-"*79
  puts hr
  puts "Building the Gem and Ocra Executable"
  puts "===================================="
  puts
  puts "Use the following command line to build and install the gem, then"
  puts "build the executable (by letting Ocra run the gem)."
  puts 
  puts "rake clean gem && gem install pkg\\torrentprocessor-#{PKG_VERSION}.gem -l --no-ri --no-rdoc && rake exe"
  puts
  puts "The executable will be located in the build dir when finished."
  puts
  puts hr
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
task :incVersion do
    ver = VersionIncrementer.new
    ver.incBuild( "#{APPNAME}.ver" )
    ver.writeSetupIni( "setup/VerInfo.ini" )
    $APPVERSION = ver.version
end


#############################################################################
SPEC = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.summary = "Process torrent files"
  s.name = PROJNAME.downcase
  s.version = PKG_VERSION
  s.requirements << 'none'
  s.bindir = 'bin'
  s.require_path = 'lib'
  #s.autorequire = 'rake'
  s.files = PKG_FILES
  s.executables = "torrentprocessor"
  s.author = "Jeff McAffee"
  s.email = "gems@ktechdesign.com"
  s.homepage = "http://gems.ktechdesign.com"
  s.description = <<EOF
TorrentProcessor will process torrent downloads to copy, move and delete
torrents throughout the torrent processing lifecycle.
EOF
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
