##############################################################################
# File::    q_bit_torrent_adapter.rb
# Purpose:: Adapter for UTorrent
# 
# Author::    Jeff McAffee 2015-02-17
# Copyright:: Copyright (c) 2015, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require_relative 'q_bit_torrent'

module TorrentProcessor
  module Service
    class QBitTorrentAdapter
      include TorrentProcessor::Utility::Loggable
      include TorrentProcessor::Utility::Verbosable

      def initialize(args)
        parse_args args
      end

      def app_name
        'qBitTorrent'
      end

      def settings
        # Get qBitTorrent settings
        webui.preferences
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
        torrents = webui.torrent_list
      end

      def get_torrent_job_properties torrent_hash
        webui.properties torrent_hash
      end

      def set_job_properties props
        log 'QBitTorrentAdapter#set_job_properties method is not supported on WebUI'
        raise 'QBitTorrentAdapter#set_job_properties method is not supported on WebUI'
        #webui.set_job_properties props
      end

      def torrents_removed?
        !removed_torrents(false).empty?
      end

      ###
      # Return array of torrent hashes that have been removed since the last
      # #removed_torrents call.
      #
      # refresh_cache: if true (default), the cache will be updated with the
      #                latest list of torrent hashes (and you will not get
      #                the same 'removed torrents' list again).
      #                Use false to prevent the cache update.
      #

      def removed_torrents refresh_cache = true
        cache_file = Pathname(@cfg.app_path) + 'qbtcache.yml'
        cached_torrents = YAML.load_file(cache_file) if cache_file.exist?
        cached_torrents ||= []

        current_torrents = webui.torrent_list
        current_torrents.map! { |t| t['hash'] }

        removed = cached_torrents.select { |h| !current_torrents.include?(h) }

        # If we're forcing a refresh (default) or the current cache list is empty:
        if refresh_cache || cached_torrents.empty?
          File.open(cache_file, 'w+') { |f| f.write(YAML.dump(current_torrents)) }
        end

        removed
      end

      ###
      # Return list of cached torrents
      #
      def torrents
        @cached_torrents ||= webui.torrent_list
      end

      def remove_torrent torrent_hash
        webui.delete_torrent_and_data torrent_hash
      end

      def get_torrent_seed_ratio torrent_hash, default_ratio
        webui.properties( torrent_hash ).fetch('share_ratio', default_ratio)
      end

      def apply_seed_limits torrent_hashes, filters
        log "QBitTorrentAdapter#apply_seed_limits is not yet supported"
        return

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
        #webui.rssfilters
        log "QBitTorrentAdapter#rssfilters are not yet supported"
        []
      end

      def rssfeeds
        #webui.rssfeeds
        log "QBitTorrentAdapter#rssfeeds are not yet supported"
        []
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
      # qBitTorrent repeatedly to get each value.
      #
      def populate_app_prefs
        prefs = webui.preferences

        @seed_ratio = 0
        @completed_downloads_dir = prefs.fetch('save_path', '')

        # The search for an existing directory fails if the completed
        # downloads dir string ends with a back slash (in winBLOWs) so strip
        # if off if it exists.
        #@completed_downloads_dir = @completed_downloads_dir[0..-2] if @completed_downloads_dir.end_with?('\\')
      end
    end # class QBitTorrentAdapter
  end
end
