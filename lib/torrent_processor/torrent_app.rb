##############################################################################
# File::    torrent_app.rb
# Purpose:: Torrent Application interface
#
# Author::    Jeff McAffee 2015-02-11
# Copyright:: Copyright (c) 2015, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require_relative 'service/u_torrent_adapter'

module TorrentProcessor

  ##########################################################################
  # TorrentApp class
  class TorrentApp
    extend Forwardable
   include Utility::Loggable
   include Utility::Verbosable

    attr_reader :cfg
    attr_reader :name

    def_delegators :adapter, :seed_ratio, :completed_downloads_dir, :app_name, :torrent_list

    ###
    # TorrentApp constructor
    #
    # controller:: controller object
    #
    def initialize(args)
      parse_args args
      @args = args

      @adapter    = nil
    end

    def parse_args args
      args = defaults.merge(args)
      @cfg = args[:cfg] if args[:cfg]
      @verbose = args[:verbose] if args[:verbose]
      @logger = args[:logger] if args[:logger]
    end

    def defaults
      {
        #:logger => NullLogger,
        #:verbose => false,
      }
    end

    def adapter
      return @adapter unless @adapter.nil?

      @adapter = Service::UTorrentAdapter.new(@args)
    end
  end # class
end # module
