##############################################################################
# File:: gemhelp.rake
# Purpose:: Tasks that help with creating gems.
# 
# Author::    Jeff McAffee 10/04/2011
#
##############################################################################

require 'rubygems'
require 'rubygems/package_task'
require 'rake'
require 'rake/clean'

# Add the pkg dir to the clean task
CLEAN.include("pkg")

# Add the pkg dir and install script to the clobber task
CLOBBER.include("pkg", "install.cmd")

#######################################

desc "Documentation for building gem"
task :help => "gemhelp:help"
	
desc "Generate install.cmd to build and install gem"
task :createscript => "gemhelp:createscript"

desc "List files to be included in gem"
task :pkg_list => "gemhelp:pkg_list"

desc "Build the gem"
task :gem => ['gemhelp:init', 'gemhelp:gem']
#task :gem do
#	Rake::Task['gemhelp:gem'].invoke(SPEC)
#end



namespace :gemhelp do

  #######################################

	task :init do
		noErrs = true

		if(!defined?(PROJNAME) == nil || PROJNAME.empty?)
			puts "* ERROR: dbg: PROJNAME constant must be defined."
			noErrs = false
		end
		
		if(!defined?(PKG_VERSION) == nil || PKG_VERSION.empty?)
			puts "* ERROR: dbg: PKG_VERSION constant must be defined."
			noErrs = false
		end
		
		if(!defined?(PKG_FILES) == nil || PKG_FILES.empty?)
			puts "* ERROR: dbg: PKG_FILES constant must be defined."
			noErrs = false
		end
		
		if(!defined?(SPEC) == nil)
			puts "* ERROR: dbg: SPEC constant must be defined."
			noErrs = false
		end

		exit unless noErrs
		
	end


  #######################################
	
	task :help => :init do
		hr = "-"*79
		puts hr
		puts "Building the Gem"
		puts "================"
		puts
		puts "Use the following command line to build and install the gem"
		puts 
		puts "rake clean gem && gem install pkg\\#{PROJNAME.downcase}-#{PKG_VERSION}.gem -l --no-ri --no-rdoc"
		puts
		puts "See also the 'createscript' task which will create a cmd script to build and install the gem."
		puts
		puts hr
	end


  #######################################
	
#	desc "Generate a simple script to build and install this gem"
	task :createscript => :init do
		scriptname = "install.cmd"
		if(File.exists?(scriptname))
			puts "Removing existing script."
			rm scriptname
		end
		
		File.open(scriptname, 'w') do |f|
			f << "::\n"
			f << ":: #{scriptname}\n"
			f << "::\n"
			f << ":: Running this script will generate and install the #{PROJNAME} gem.\n"
			f << ":: Run 'rake createscript' to regenerate this script.\n"
			f << "::\n"

			f << "rake clean gem && gem install pkg\\#{PROJNAME.downcase}-#{PKG_VERSION}.gem -l --no-ri --no-rdoc\n"
		end
	end


  #######################################
	
	task :pkg_list => :init do
		puts "PKG_FILES (will be included in gem):"
		PKG_FILES.each do |f|
			puts "  #{f}"
		end
	end


  #######################################
	
	Gem::PackageTask.new(SPEC) do |pkg|
		pkg.need_zip = true
		pkg.need_tar = true
		
		puts "PKG_VERSION: #{PKG_VERSION}" if $verbose
	end


  #######################################

end # namespace :gemhelp
