##############################################################################
# File::    torrent_app.rb
# Purpose:: Torrent Application interface
#
# Author::    Jeff McAffee 2015-02-11
# Copyright:: Copyright (c) 2015, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require_relative 'service/u_torrent_adapter'
require_relative 'service/q_bit_torrent_adapter'

module TorrentProcessor

  ##########################################################################
  # TorrentApp class
  class TorrentApp
    extend Forwardable
   include Utility::Loggable
   include Utility::Verbosable

    attr_reader :cfg
    attr_reader :name
    attr_reader :webui_type

    def_delegators  :adapter,
                    :seed_ratio,
                    :completed_downloads_dir,
                    :app_name,
                    :torrent_list,
                    :get_torrent_job_properties,
                    :set_job_properties,
                    :torrents_removed?,
                    :removed_torrents,
                    :torrents,
                    :remove_torrent,
                    :get_torrent_seed_ratio,
                    :apply_seed_limits,
                    :settings,
                    :rssfilters,
                    :rssfeeds,
                    :dump_job_properties

    ###
    # TorrentApp constructor
    #
    # controller:: controller object
    #
    def initialize(args)
      @adapter    = nil

      if args[:webui] and !args[:webui_type]
        raise ":webui_type required when :webui provided"
      end
      parse_args args
    end

    def parse_args args
      args = defaults.merge(args)
      @init_args = args

      @cfg        = args[:cfg]        if args[:cfg]
      @verbose    = args[:verbose]    if args[:verbose]
      @logger     = args[:logger]     if args[:logger]
      @webui_type = @cfg.backend if (@cfg.respond_to?(:backend) && !@cfg.backend.nil?)
      @webui_type = args[:webui_type] if args[:webui_type]
      @adapter    = args[:adapter]    if args[:adapter]
    end

    def defaults
      {
        #:logger => NullLogger,
        #:verbose => false,
        :webui_type => :utorrent,
      }
    end

    def adapter
      return @adapter unless @adapter.nil?

      if @webui_type == :utorrent
        @adapter = Service::UTorrentAdapter.new(@init_args)
      elsif @webui_type == :qbtorrent
        @adapter = Service::QBitTorrentAdapter.new(@init_args)
      else
        raise "Unknown webui_type: :#{@webui_type}"
      end
    end

    ###
    # Override Verbosable verbose= to set flag on attached objects
    #

    def verbose= flag
      @verbose = flag
      adapter.verbose = flag if @adapter
    end
  end # class
end # module
