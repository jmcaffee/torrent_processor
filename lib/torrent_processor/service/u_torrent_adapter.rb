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
      include TorrentProcessor::Utility::Loggable
      include TorrentProcessor::Utility::Verbosable

      def initialize(args)
        parse_args args
      end

      def app_name
        'uTorrent'
      end

      def settings
        # Get uTorrent settings
        webui.get_utorrent_settings
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

      def get_torrent_job_properties torrent_hash
        webui.get_torrent_job_properties torrent_hash
      end

      def set_job_properties props
        webui.set_job_properties props
      end

      def torrents_removed?
        webui.torrents_removed?
      end

      def removed_torrents
        webui.removed_torrents
      end

      ###
      # Return list of cached torrents
      #
      def torrents
        webui.torrents
      end

      def remove_torrent torrent_hash
        webui.remove_torrent torrent_hash
      end

      def get_torrent_seed_ratio torrent_hash, default_ratio
        target_ratio = default_ratio

        # This torrent may have an overridden target seed ratio.
        # Pull down the torrent job properties to check and see.
        response = webui.get_torrent_job_properties( torrent_hash )
        if (! response["props"].nil? )

          props = response["props"][0]
          seed_override = props["seed_override"]
          seed_ratio = props["seed_ratio"]
          if (seed_override == 1)
            target_ratio = Integer(seed_ratio)
          end
        end

        target_ratio
      end

      def apply_seed_limits torrent_hashes, filters

        filter_props = {}

        # For each torrent, get its properties and apply a seed limit if needed.
        torrent_hashes.each do |tdata|
          hash = tdata[:hash]
          name = tdata[:name]

          response = get_torrent_job_properties( hash )
          if (! response["props"].nil? )

            props = response["props"][0]
            seed_override = props["seed_override"]
            seed_ratio = props["seed_ratio"]
            raw_trackers = props["trackers"]

            if (seed_override != 1)   # Don't bother if an override is already set.

              # Break the list of trackers into individual strings and load the filters (if any).
              trackers = raw_trackers.split("\r\n")

              # Check each tracker against all filters looking for a match.
              if (! trackers.nil? && trackers.length > 0 )
                if (! filters.nil? && filters.length > 0 )
                  trackers.each do |tracker|
                    filters.each do |filtered_tracker, limit|
                      if ( tracker.include?(filtered_tracker) )

                        # Found a match... add it to the props list to be applied when we're finished here.
                        filter_props[hash] = {"seed_override" => 1, "seed_ratio" => Integer(limit)}
                        log( "Applying tracker filter to #{name}." )
                        log( "    seed_ratio: #{limit}" )
                      end   # tracker includes filtered_tracker
                    end   # each filter
                  end   # each tracker
                end   # filters not empty
              end   # trackers not empty
            end   # seed override not in effect
          end   # props not nil
        end   # each row

        if ( filter_props.length > 0 )
          response = set_job_properties( filter_props )
        end
      end

      def rssfilters
        webui.rssfilters
      end

      def rssfeeds
        webui.rssfeeds
      end

    private

      def parse_args args
        args = defaults.merge(args)
        @cfg      = args[:cfg]      if args[:cfg]
        @verbose  = args[:verbose]  if args[:verbose]
        @logger   = args[:logger]   if args[:logger]
        @webui    = args[:webui]    if args[:webui]
        @database = args[:database] if args[:database]

        unless @cfg.nil?
          @ip   = @cfg.utorrent.ip
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

