##############################################################################
# File::    runtime.rb
# Purpose:: Runtime Configuration/Environment
# 
# Author::    Jeff McAffee 01/10/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

module Runtime
  class << self
    attr_accessor :service
  end

  def self.configure
    self.service ||= Service.new
    yield(service) if block_given?
  end

  class Service
    attr_accessor :utorrent
    attr_accessor :moviedb
    attr_accessor :database
    attr_accessor :logger
  end
end

Runtime.configure
