##############################################################################
# File::    base_plugin.rb
# Purpose:: Torrent App Base Plugin class.
#
# Author::    Jeff McAffee 2015-02-15
# Copyright:: Copyright (c) 2015, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

module TorrentProcessor
  module Plugin

  class BasePlugin
    include TorrentProcessor::Utility::Loggable

    attr_reader :init_args, :cfg, :webui, :webui_type, :database

  protected

    def parse_args args
      @init_args = {}
      args = defaults.merge(args)
      @init_args = args

      @cfg        = args[:cfg]        if args[:cfg]
      @logger     = args[:logger]     if args[:logger]
      @webui      = args[:webui]      if args[:webui]
      @webui_type = args[:webui_type] if args[:webui_type]
      @database   = args[:database]   if args[:database]
    end

    def defaults
      {
        :logger     => NullLogger
      }
    end
  end # class

  end # module
end # module
