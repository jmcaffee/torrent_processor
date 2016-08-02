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
      include TorrentProcessor::Utility::Normalizable

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
        converted_torrent_list(webui.torrent_list)
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
      # Return hash of torrents that have been removed since the last
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

        all_torrents = webui.torrent_list
        current_torrents = all_torrents.clone
        current_torrents.map! { |t| t['hash'] }

        removed = cached_torrents.select { |h| !current_torrents.include?(h) }

        # If we're forcing a refresh (default) or the current cache list is empty:
        if refresh_cache || cached_torrents.empty?
          File.open(cache_file, 'w+') { |f| f.write(YAML.dump(current_torrents)) }
        end

        removed_torrent_data = {}
        removed.each { |hsh| removed_torrent_data[hsh] = 'removed' }

        removed_torrent_data
      end

      ###
      # Return list of cached torrents
      #
      def torrents
        @cached_torrents ||= converted_torrent_list(webui.torrent_list)
      end

      def remove_torrent torrent_hash
        webui.delete_torrent_and_data torrent_hash
      end

      def get_torrent_seed_ratio torrent_hash, default_ratio
        data = webui.properties torrent_hash
        data ||= {}
        normalize_percent(
          data.fetch('share_ratio', default_ratio) )
      end

      def apply_seed_limits torrent_hashes, filters
        #log "QBitTorrentAdapter#apply_seed_limits is not yet supported"
        #return

        limits = {}

        # For each torrent, get its properties and apply a seed limit if needed.
        torrent_hashes.each do |tdata|
          hash = tdata[:hash]
          name = tdata[:name]

          trackers = get_trackers hash

          # Check each tracker against all filters looking for a match.
          if (! trackers.nil? && trackers.length > 0 )
            if (! filters.nil? && filters.length > 0 )
              trackers.each do |tracker|
                filters.each do |filtered_tracker, limit|
                  if ( tracker["url"].include?(filtered_tracker) )

                    limits[hash] = limit
                    log( "Applying tracker filter to #{name}." )
                    log( "    seed_ratio: #{limit}" )
                  end   # tracker includes filtered_tracker
                end   # each filter
              end   # each tracker
            end   # filters not empty
          end   # trackers not empty

        end # each torrent hash

        limits
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

      def dump_job_properties torrent_hash
        # We want ALL the data, so we've go to go directly to the webui.
        webui.torrent_list.each do |t|
          hash = t['hash']
          if hash == torrent_hash
            # qbt torrent data is split into the list data, and properties data.
            props = webui.properties hash
            # Merge the properties data in to the list data.
            t.merge(props)

            write_raw_torrent_properties t, webui.trackers(torrent_hash)
          end
        end
      end

      def get_trackers torrent_hash
        webui.trackers torrent_hash
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
          @ip   = @cfg.qbtorrent.ip
          @port = @cfg.qbtorrent.port
          @user = @cfg.qbtorrent.user
          @pass = @cfg.qbtorrent.pass
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

        @webui = QbtClient::WebUI.new(@ip, @port, @user, @pass)
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

        # Seed ratio is not provided by qBitTorrent at this time.
        @seed_ratio = 0
        @completed_downloads_dir = prefs.fetch('save_path', '')

        # The search for an existing directory fails if the completed
        # downloads dir string ends with a back slash (in winBLOWs) so strip
        # if off if it exists.
        #@completed_downloads_dir = @completed_downloads_dir[0..-2] if @completed_downloads_dir.end_with?('\\')
      end

      ###
      # Convert the torrent data structure to a common format for the app
      #

      def converted_torrent_list torrent_list_data
        converted_torrents = {}

        torrent_list_data.each do |t|
          hash = t['hash']
          # qbt torrent data is split into the list data, and properties data.
          props = webui.properties hash
          unless props.nil?
            # Merge the properties data in to the list data.
            converted_torrents[hash] = TorrentProcessor::Service::QBitTorrent::TorrentData.new(t.merge(props))

            # Convert floating point percentages to integer where 1000 = 100%
            converted_torrents[hash].normalize_percents
          end
        end

        converted_torrents
      end

      def write_raw_torrent_properties torrent_data, trackers
        log "Name: #{torrent_data.fetch('name')}"

        tab = "  "
        log "Props:"
        log tab + "hash: " + torrent_data.fetch("hash")
        log tab + "ulrate:     " + torrent_data.fetch("upspeed").to_s
        log tab + "dlrate:     " + torrent_data.fetch("dlspeed").to_s
        log tab + "eta:        " + torrent_data.fetch("eta").to_s
        log tab + "num_leechs: " + torrent_data.fetch("num_leechs").to_s
        log tab + "num_seeds:  " + torrent_data.fetch("num_seeds").to_s
        log tab + "priority:   " + torrent_data.fetch("priority").to_s
        log tab + "progress:   " + torrent_data.fetch("progress").to_s
        log tab + "seed_ratio: " + torrent_data.fetch("ratio").to_s
        log tab + "size:       " + torrent_data.fetch("size").to_s
        log tab + "state:      " + torrent_data.fetch("state").to_s
        log
        log tab + "trackers: "
        trackers.each do |tracker|
          log tab + tab + "msg:       " + tracker.fetch("msg")
          log tab + tab + "num_peers: " + tracker.fetch("num_peers").to_s
          log tab + tab + "status:    " + tracker.fetch("status")
          log tab + tab + "url:       " + tracker.fetch("url")
          log tab + tab + "-"*10
        end
        log
        log "------------------------------------"
        log
      end
    end # class QBitTorrentAdapter
  end
end

