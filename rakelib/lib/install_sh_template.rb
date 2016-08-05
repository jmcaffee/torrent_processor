##############################################################################
# File::    install_sh_template.rb
# Purpose:: Generate a shell script to install Torrent Processor
# 
# Author::    Jeff McAffee 2016-08-03
# Copyright:: Copyright (c) 2016, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'erb'

class InstallShTemplate

  attr_accessor :app_name, :app_version, :template

  def initialize
    @app_name = ""
    @app_version = ""
    @template = 'rakelib/lib/templates/install.sh.erb'
  end

  def create_script(to)
    #erb = File.read(File.expand_path("../templates/#{@from}", __FILE__))
    erb = File.read(@template)
    trim_mode = '<>' # omit newline for lines starting with <% and ending in %>
    File.open(to, 'w') do |f|
      f.write(ERB.new(erb, nil, trim_mode).result(binding))
    end
  end
end

