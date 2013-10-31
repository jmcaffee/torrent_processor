##############################################################################
# File::    iss_script_template.rb
# Purpose:: Generate an Inno Installer build script
# 
# Author::    Jeff McAffee 10/30/2013
# Copyright:: Copyright (c) 2013, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'erb'

class IssScriptTemplate

  attr_accessor :app_name, :app_version, :template

  def initialize
    @app_name = ""
    @app_version = ""
    @template = 'rakelib/lib/templates/installer.iss.erb'
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

