##############################################################################
# File::    processor.rb
# Purpose:: Model object for TorrentProcessor.
#
# Author::    Jeff McAffee 07/31/2011
# Copyright:: Copyright (c) 2011, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'ktcommon/ktpath'
require 'ktcommon/ktcmdline'
require_relative 'plugin'


module TorrentProcessor

  ##########################################################################
  # Processor class
  class Processor
    include Utility::Loggable
    include Utility::Verbosable
    include Plugin

    # Torrent state constants

    STATE_DOWNLOADING = 'downloading'
    STATE_DOWNLOADED  = 'downloaded'
    STATE_PROCESSING  = 'processing'
    STATE_PROCESSED   = 'processed'
    STATE_SEEDING     = 'seeding'
    STATE_REMOVING    = 'removing'

  attr_reader     :cfg
  attr_reader     :database
  attr_reader     :moviedb

    ###
    # Processor constructor
    #
    def initialize(args)
      parse_args args

      ProcessorPluginManager.remove_all
      ProcessorPluginManager.register [TorrentCopier,
                                       Unrar]
    end

    def parse_args args
      args = defaults.merge(args)
      @init_args = args

      @logger   = args[:logger]   if args[:logger]
      @verbose  = args[:verbose]  if args[:verbose]
      @cfg      = args[:cfg]      if args[:cfg]
      @moviedb  = args[:moviedb]  if args[:moviedb]
      @database = args[:database] if args[:database]
      @torrent_app = args[:torrent_app] if args[:torrent_app]
    end

    def defaults
      {
        :cfg        => TorrentProcessor.configuration,
      }
    end


    ###
    # Override Verbosable verbose= to set flag on attached objects
    #

    def verbose= flag
      @verbose = flag

      @moviedb.verbose      = flag if @moviedb
      @torrent_app.verbose  = flag if @torrent_app
      @database.verbose     = flag if @database
    end

    def torrent_app
      return @torrent_app unless @torrent_app.nil?

      @torrent_app = TorrentApp.new(@init_args)
    end

    ###
    # Process torrent files retrieved from Torrent application
    #
    def process()
      retrieve_torrent_app_settings()

      log( "Requesting torrent list update" )

      # Get a list of torrents.
      torrents = torrent_app.torrent_list

      # Update the db's list of torrents.
      database.update_torrents( torrents )

      # Apply filters if needed.
      # NOTE: The seed limits are only applied to 'new' torrents. This should limit the application so that
      # limits aren't needlessly applied everytime the torrents are processed.
      apply_seed_limit_filters()

      # Update the db torrent list states
      update_torrent_states()

      # Remove any torrents from the db that have been removed from torrent app (due to a request).
      if torrent_app.torrents_removed?
        remove_torrents( torrent_app.removed_torrents )
      else
        # 'Cleanup' DB by removing torrents that are in the DB (STATE_REMOVING)
        # but are no longer in the (torrent app) torrents list due to missing a cache.
        # By missing a cache, torrent app is not sending the 'removed' torrents, only what is currently in its list.
        remove_missing_torrents( torrent_app.torrents )
      end

      # Process torrents that are awaiting processing.
      process_torrents_awaiting_processing()

      # Process torrents that have completed processing.
      update_torrents_completed_processing()

      # Process torrents that have completed seeding.
      process_torrents_completed_seeding()

      move_completed_movies()
    end


    ###
    # Retrieve the current Torrent App settings. seed_ratio in particular.
    #
    def retrieve_torrent_app_settings()
      app_name = torrent_app.app_name
      log( "--- Requesting #{app_name} Settings ---" )

      seed_ratio = torrent_app.seed_ratio
      dir_completed_download = torrent_app.completed_downloads_dir


      case app_name
      when 'uTorrent'
        # Store utorrent data in the configuration object.
        TorrentProcessor.configure do |config|
          config.utorrent.seed_ratio              = seed_ratio
          config.utorrent.dir_completed_download  = dir_completed_download
        end

      when 'qBitTorrent'
        # Store utorrent data in the configuration object.
        TorrentProcessor.configure do |config|
          config.qbtorrent.seed_ratio              = seed_ratio
          config.qbtorrent.dir_completed_download  = dir_completed_download
        end
      end

      TorrentProcessor.save_configuration

      log( "    #{app_name} seed ratio: #{seed_ratio.to_s}" )
      log( "    #{app_name} completed download dir: #{dir_completed_download}" )
    end


    ###
    # Apply seed limit filters to new torrents. Torrents are considered 'new' if they don't have a state (tp_state)
    #
    def apply_seed_limit_filters()
        # Get list of torrents where state = NULL
        q = "SELECT hash, percent_progress, name FROM torrents WHERE tp_state IS NULL;"
        rows = database.execute(q)

        # Create an array of hashes containing a torrent hash and a torrent name.
        torrents_to_update = rows.map { |r| { hash: r[0], name: r[2] } }

        # Apply seed limits to given torrents.
        # FIXME: Implement app stored target ratios once qBitTorrent allows
        # sending/receiving target ratios.
        #torrent_app.apply_seed_limits torrents_to_update, cfg.filters
        apply_seed_limits torrents_to_update, cfg.filters
    end


    ###
    # Update torrent states within the DB
    #
    def update_torrent_states()
        # Get list of torrents where state = NULL
        q = "SELECT hash, percent_progress, name FROM torrents WHERE tp_state IS NULL;"
        rows = database.execute(q)

        # For each torrent where download percentage < 100, set state = STATE_DOWNLOADING
        rows.each do |r|
          if r[1] < 1000
            database.update_torrent_state(r[0], STATE_DOWNLOADING)
            log( "State set to STATE_DOWNLOADING: #{r[2]}" )
          else
            database.update_torrent_state(r[0], STATE_DOWNLOADED)
            log( "State set to STATE_DOWNLOADED: #{r[2]}" )
          end
        end

        # Get list of torrents where state = STATE_DOWNLOADING
        q = "SELECT hash, percent_progress, name FROM torrents WHERE tp_state = \"#{STATE_DOWNLOADING}\";"
        rows = database.execute(q)

        # For each torrent where download percentage = 100, set state = STATE_DOWNLOADED
        rows.each do |r|
          if r[1] >= 1000
            database.update_torrent_state(r[0], STATE_DOWNLOADED)
            log( "State set to STATE_DOWNLOADED: #{r[2]}" )
          end
        end

        # Get list of torrents where state = STATE_DOWNLOADED
        q = "SELECT hash, name FROM torrents WHERE tp_state = \"#{STATE_DOWNLOADED}\";"
        rows = database.execute(q)

        # For each torrent where state = STATE_DOWNLOADED, set state = STATE_PROCESSING
        rows.each do |r|
          database.update_torrent_state(r[0], STATE_PROCESSING)
          log( "State set to STATE_PROCESSING: #{r[1]}" )
        end

    end


    ###
    # Remove torrents from DB that have been removed from torrent app
    #
    # torrents:: torrents that have been removed
    #
    def remove_torrents(torrents)
        # From DB - Get list of torrents that are STATE_REMOVING
        q = "SELECT hash, name FROM torrents WHERE tp_state = \"#{STATE_REMOVING}\";"
        rows = database.execute(q)

        # For each torrent in awaiting list, remove it if the removed list contains its hash
        rows.each do |r|
          if torrents.has_key?(r[0])
            # Remove it from DB and removal list
            database.delete_torrent( r[0] )
            torrents.delete( r[0] )
            # Log it
            log( "Torrent removed (as requested): #{r[1]}" )
          end
        end

        # For remaining torrents in removal list, remove them from DB and removal list
        torrents.each do |hash, t|
          database.delete_torrent( hash )
          # Log it
          log( "Torrent removed (NOT requested): #{hash}" )
        end

    end


    ###
    # Remove torrents from DB that have been removed from torrent app
    #
    # torrents:: current list of torrents passed from torrent app
    #
    def remove_missing_torrents(torrents)
        log( "Removing (pending removal) torrents from DB that are no longer in the torrent app list" )

        # From DB - Get list of torrents that are STATE_REMOVING
        q = "SELECT hash, name FROM torrents WHERE tp_state = \"#{STATE_REMOVING}\";"
        rows = database.execute(q)


        # For each torrent in awaiting list, remove it if the torrent list DOES NOT contains its hash
        removed_count = 0
        rows.each do |r|
          if !torrents.has_key?(r[0])
            # Remove it from DB
            log( "    Torrent removed from DB: #{r[1]}" )
            database.delete_torrent( r[0] )
            removed_count += 1
          end
        end

        log("    No torrents were removed.") if (removed_count < 1)
    end


    ###
    # Process torrents that are awaiting processing
    #
    def process_torrents_awaiting_processing()
        # Get list of torrents from DB where state = STATE_PROCESSING
        q = "SELECT hash, name, folder, label FROM torrents WHERE tp_state = \"#{STATE_PROCESSING}\";"
        rows = database.execute(q)

        # For each torrent, process it
        rows.each do |r|
          torrent = { hash: r[0], filename: r[1], filedir: r[2], label: r[3] }

          log( "Processing torrent: #{torrent[:filename]} (in #{torrent[:filedir]})" )

          begin

            args = {
              :logger => @logger,
              :cfg => cfg,
              :database => database,
            }
            ProcessorPluginManager.execute_each( args, torrent)

            # For each torrent, if processed successfully (file copied), set state = STATE_PROCESSED
            database.update_torrent_state( r[0], STATE_PROCESSED )
            log( "    Torrent processed successfully: #{torrent[:filename]}" )

          rescue Plugin::PluginError => e

            log "    Processing aborted for torrent: #{torrent[:filename]}"
            log "      Reason: #{e.message}"

          end
        end

    end

    ###
    # Process torrents that have completed processing
    #
    def update_torrents_completed_processing()
        # Get list of torrents from DB where state = STATE_PROCESSED
        q = "SELECT hash, name FROM torrents WHERE tp_state = \"#{STATE_PROCESSED}\";"
        rows = database.execute(q)

        # For each torrent, set state = STATE_SEEDING
        rows.each do |r|
          database.update_torrent_state( r[0], STATE_SEEDING )
          log( "State set to STATE_SEEDING: #{r[1]}" )
        end

    end


    ###
    # Process torrents that have completed seeding
    #
    def process_torrents_completed_seeding()
        # Get list of torrents from DB where state = STATE_SEEDING
        q = "SELECT hash, ratio, name FROM torrents WHERE tp_state = \"#{STATE_SEEDING}\";"
        rows = database.execute(q)

        # For each torrent, if ratio >= target ratio
        rows.each do |r|
          target_ratio = get_target_seed_ratio( r[2], r[0] )
          log "Torrent [#{r[2]}] current ratio: #{r[1]}"

          # Infinite seeding if target ratio is -1
          next if target_ratio < 0

          if ( Integer(r[1]) >= target_ratio )
            # Set state = STATE_REMOVING
            database.update_torrent_state( r[0], STATE_REMOVING )
            log( "State set to STATE_REMOVING: #{r[2]}" )

            # Request removal via torrent app
            torrent_app.remove_torrent( r[0] )
            log( "Removal request sent: #{r[2]}" )
          end
        end

    end


    ###
    # Determine the target seed ratio for a torrent.
    #
    # Because qBitTorrent does not yet support sending/receiving target ratios
    # on a per-torrent basis, we'll handle our own targets through the DB.
    #
    def get_target_seed_ratio(name, hash)
      base_ratio = TorrentProcessor.configuration.seed_ratio

      # This torrent may have an overridden target seed ratio.
      # FIXME: Implement app stored target ratios once qBitTorrent allows
      # sending/receiving target ratios.
      #target_ratio = torrent_app.get_torrent_seed_ratio hash, base_ratio
      target_ratio = database.read_torrent_target_ratio hash
      if target_ratio != base_ratio
        log( "Torrent [#{name}] has overridden target seed ratio" )
        log( "  target ratio = #{target_ratio}" )
      else
        log( "Torrent [#{name}] target seed ratio: #{target_ratio}" )
      end

      # Add some padding to the target ratio since the final ratio is almost
      # never exactly reached.
      # 5 = .05 percent.
      if target_ratio > 5
        target_ratio = target_ratio - 5
      end
      target_ratio
    end


    ###
    # Move completed movies to the final directory (where XBMC looks)
    #
    def move_completed_movies
      if !moviedb.nil?
        mover = MovieMover.new(:movie_db => moviedb, :logger => @logger)
        mover.process(cfg.movie_processing,
                      cfg.tmdb.target_movies_path,
                      cfg.tmdb.can_copy_start_time,
                      cfg.tmdb.can_copy_stop_time)
      end
    end

    private

      def apply_seed_limits torrents_to_update, filters
        changes = torrent_app.apply_seed_limits torrents_to_update, filters

        if changes.is_a? Hash
          changes.each do |hash, limit|
            database.update_torrent_target_ratio hash, limit
          end
        end
      end
  end # class Processor
end # module TorrentProcessor
