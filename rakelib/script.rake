##############################################################################
# File::    script.rb
# Purpose:: Generate startup scripts
#
# Author::    Jeff McAffee 2015-02-04
# Copyright:: Copyright (c) 2015, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require_relative 'lib/start_cmd_template'
require_relative 'lib/start_sh_template'
require_relative 'lib/install_sh_template'
require_relative 'lib/uninstall_sh_template'
require_relative 'lib/ext/string'

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

  desc "generate a 'nix startup script"
  task :generate_sh do

    script = "build/#{PROJNAME.snakecase}"
    rm_f script if File.exists? script

    templater = StartShTemplate.new
    templater.app_name = PROJNAME
    templater.app_version = PKG_VERSION
    templater.template = 'rakelib/lib/templates/start.sh.erb'
    templater.create_script script

    File.chmod(0755, script)
  end

  desc "generate a 'nix install script"
  task :generate_install_sh do

    script = "build/install.sh"
    rm_f script if File.exists? script

    templater = InstallShTemplate.new
    templater.app_name = PROJNAME
    templater.app_version = PKG_VERSION
    templater.template = 'rakelib/lib/templates/install.sh.erb'
    templater.create_script script

    File.chmod(0744, script)
  end

  desc "generate a 'nix uninstall script"
  task :generate_uninstall_sh do

    script = "build/uninstall.sh"
    rm_f script if File.exists? script

    templater = UninstallShTemplate.new
    templater.app_name = PROJNAME
    templater.app_version = PKG_VERSION
    templater.template = 'rakelib/lib/templates/uninstall.sh.erb'
    templater.create_script script

    File.chmod(0744, script)
  end
end
