##############################################################################
# File::    u_torrent_adapter.rb
# Purpose:: Adapter for UTorrent
# 
# Author::    Jeff McAffee 02/11/2015
# Copyright:: Copyright (c) 2015, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require_relative 'utorrent'

module TorrentProcessor
  module Service
    class UTorrentAdapter
      def initialize(args)
        parse_args args
      end

      def app_name
        'uTorrent'
      end

      def seed_ratio
        return @seed_ratio unless @seed_ratio.nil?

        populate_app_prefs
        @seed_ratio
      end

      def completed_downloads_dir
        return @completed_downloads_dir unless @completed_downloads_dir.nil?

        populate_app_prefs
        @completed_downloads_dir
      end

      def torrent_list
        # Get a list of torrents.
        cacheID = database.read_cache()
        torrents = webui.get_torrent_list( cacheID )
        database.update_cache( webui.cache )
        torrents
      end

    private

      def parse_args args
        args = defaults.merge(args)
        @cfg = args[:cfg] if args[:cfg]
        @verbose = args[:verbose] if args[:verbose]
        @logger = args[:logger] if args[:logger]
        @webui = args[:webui] if args[:webui]
        @database = args[:database] if args[:database]

        unless @cfg.nil?
          @ip = @cfg.utorrent.ip
          @port = @cfg.utorrent.port
          @user = @cfg.utorrent.user
          @pass = @cfg.utorrent.pass
        end
      end

      def defaults
        {
          #:logger => NullLogger,
          #:verbose => false,
        }
      end

      def webui
        return @webui unless @webui.nil?

        @webui = UTorrent::UTorrentWebUI.new(@ip, @port, @user, @pass)
      end

      def database
        @database
      end

      ###
      # Populate all preference values at once so we don't have to call
      # uTorrent repeatedly to get each value.
      #
      def populate_app_prefs
        prefs = webui.get_utorrent_settings

        prefs.each do |i|
          if i[0] == "seed_ratio"
            @seed_ratio = Integer(i[2])
            next
          end

          if i[0] == "dir_completed_download"
            @completed_downloads_dir = i[2]
            # The search for an existing directory fails if the completed
            # downloads dir string ends with a back slash (in winBLOWs) so strip
            # if off if it exists.
            @completed_downloads_dir = @completed_downloads_dir[0..-2] if @completed_downloads_dir.end_with?('\\')
            next
          end
        end
      end
    end # class UTorrentAdapter
  end
end

