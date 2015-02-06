##############################################################################
# File::    script.rb
# Purpose:: Generate startup scripts
#
# Author::    Jeff McAffee 2015-02-04
# Copyright:: Copyright (c) 2015, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require_relative 'lib/start_cmd_template'

namespace :script do
  desc "generate a windows startup script"
  task :generate_cmd do

    script = "build/#{PROJNAME}.cmd"
    rm_f script if File.exists? script

    templater = StartCmdTemplate.new
    templater.app_name = PROJNAME
    templater.app_version = PKG_VERSION
    templater.template = 'rakelib/lib/templates/start.cmd.erb'
    templater.create_script script
  end
end
