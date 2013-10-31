##############################################################################
# File::    templater.rb
# Purpose:: Templater
#
# Author::    Jeff McAffee 10/30/2013
# Copyright:: Copyright (c) 2013, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require_relative 'lib/iss_script_template'

namespace :inno do
  desc "generate an Inno Installer build script"
  task :generate_iss do
    script = "#{PROJNAME}.iss"
    rm_f script if File.exists? script

    iss = IssScriptTemplate.new
    iss.app_name = PROJNAME
    iss.app_version = PKG_VERSION
    iss.template = 'rakelib/lib/templates/installer.iss.erb'
    iss.create_script script
  end
end
