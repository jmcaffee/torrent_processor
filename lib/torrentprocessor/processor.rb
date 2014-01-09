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
require 'utorrentwebui'
require_relative 'plugin'


module TorrentProcessor

  ##########################################################################
  # Processor class
  class Processor
    include Plugin

    # Torrent state constants

    STATE_DOWNLOADING = 'downloading'
    STATE_DOWNLOADED  = 'downloaded'
    STATE_PROCESSING  = 'processing'
    STATE_SEEDING     = 'seeding'
    STATE_REMOVING    = 'removing'

  attr_reader     :controller
  attr_reader     :srcdir
  attr_reader     :srcfile
  attr_reader     :state
  attr_reader     :prevstate
  attr_reader     :msg
  attr_reader     :label
  attr_reader     :verbose

    ###
    # Processor constructor
    #
    def initialize(controller)
      $LOG.debug "Processor::initialize"

      @controller = controller
      @srcdir     = nil
      @srcfile    = nil
      @verbose    = false
      @utorrent   = nil
      @moviedb    = nil

      ProcessorPluginManager.remove_all
      ProcessorPluginManager.register [TorrentCopierPlugin,
                                       Unrar]

    end


    ###
    # Set the srcdir
    #
    # srcdirpath:: input file path
    #
    def srcdir=(srcdirpath)
      $LOG.debug "Processor::srcdir=( #{srcdirpath} )"
      @srcdir = srcdirpath
    end


    ###
    # Set the srcfile
    #
    # srcfilepath:: input file path
    #
    def srcfile=(srcfilepath)
      $LOG.debug "Processor::srcfile=( #{srcfilepath} )"
      @srcfile = srcfilepath
    end


    ###
    # Set the current state
    #
    # state:: current torrent state
    #
    def state=(stateval)
      $LOG.debug "Processor::state=( #{stateval} )"
      @state = stateval
    end


    ###
    # Set the previous state
    #
    # stateval:: previous torrent state
    #
    def prevstate=(stateval)
      $LOG.debug "Processor::prevstate=( #{stateval} )"
      @prevstate = stateval
    end


    ###
    # Set the uTorrent msg
    #
    # msgval:: uTorrent msg
    #
    def msg=(msgval)
      $LOG.debug "Processor::msg=( #{msgval} )"
      @msg = msgval
    end


    ###
    # Set the uTorrent label
    #
    # labelval:: uTorrent label
    #
    def label=(labelval)
      $LOG.debug "Processor::label=( #{labelval} )"
      @label = labelval
    end


    ###
    # Set the verbose flag
    #
    # arg:: verbose mode if true
    #
    def verbose=(arg)
      $LOG.debug "Processor::verbose=( #{arg} )"
      @verbose = arg
    end

    def utorrent=(ut)
      @utorrent = ut
    end

    ###
    # Return a utorrent instance
    #
    def utorrent()
      $LOG.debug "Processor::utorrent()"

      return @utorrent unless @utorrent.nil?

      @utorrent = UTorrentWebUI.new(cfg[:ip], cfg[:port], cfg[:user], cfg[:pass])
    end


    ###
    # Return a moviedb instance
    #
    def moviedb()
      $LOG.debug "Processor::moviedb"

      return @moviedb unless @moviedb.nil?

      api_key = cfg[:tmdb_api_key]
      if api_key.nil? || api_key.empty?
        log "!!! No TMdb API key configured !!!"
        return nil
      end

      @moviedb = MovieDB.new(api_key)
    end

    def log msg = ''
      if @controller.respond_to? :log
        @controller.log msg
      elsif @controller.respond_to? :logger
        @controller.logger.log msg
      else
        puts msg
      end
    end

    def cfg
      @controller.cfg
    end

    ###
    # Process torrent files retrieved from UTorrent application
    #
    def process()
      $LOG.debug "Processor::process"

      retrieve_utorrent_settings()

      log( "Requesting torrent list update" )

      # Get a list of torrents.
      cacheID = @controller.database.read_cache()
      utorrent.get_torrent_list( cacheID )
      @controller.database.update_cache( utorrent.cache )

      # Update the db's list of torrents.
      @controller.database.update_torrents( utorrent.torrents )

      # Apply filters if needed.
      # NOTE: The seed limits are only applied to 'new' torrents. This should limit the application so that
      # limits aren't needlessly applied everytime the torrents are processed.
      apply_seed_limit_filters()

      # Update the db torrent list states
      update_torrent_states()

      # Remove any torrents from the db that have been removed from utorrent (due to a request).
      if utorrent.torrents_removed?
        remove_torrents( utorrent.removed_torrents )
      else
        # 'Cleanup' DB by removing torrents that are in the DB (STATE_REMOVING)
        # but are no longer in the (utorrent) torrents list due to missing a cache.
        # By missing a cache, utorrent is not sending the 'removed' torrents, only what is currently in its list.
        remove_missing_torrents( utorrent.torrents )
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
    # Retrieve the current uTorrent settings. seed_ratio in particular.
    #
    def retrieve_utorrent_settings()
      $LOG.debug "Processor::retrieve_utorrent_settings()"

      log( "--- Requesting uTorrent Settings ---" )
      settings = utorrent.get_utorrent_settings()

      seed_ratio = 0
      dir_completed_download = ''

      settings.each do |i|
        if i[0] == "seed_ratio"
          seed_ratio = Integer(i[2])
          next
        end

        if i[0] == "dir_completed_download"
          dir_completed_download = i[2]
          # The search for an existing directory fails if the completed
          # downloads dir string ends with a back slash (in winBLOWs) so strip
          # if off if it exists.
          dir_completed_download = dir_completed_download[0..-2] if dir_completed_download.end_with?('\\')
          next
        end
      end

      # Store utorrent data in the configuration object.

      TorrentProcessor.configure do |config|
        config.utorrent.seed_ratio              = seed_ratio
        config.utorrent.dir_completed_download  = dir_completed_download
      end

      log( "    uTorrent seed ratio: #{seed_ratio.to_s}" )
      log( "    uTorrent completed download dir: #{dir_completed_download}" )
    end


    ###
    # Apply seed limit filters to new torrents. Torrents are considered 'new' if they don't have a state (tp_state)
    #
    def apply_seed_limit_filters()
      $LOG.debug "Processor::apply_seed_limit_filters()"

        # Get list of torrents where state = NULL
        q = "SELECT hash, percent_progress, name FROM torrents WHERE tp_state IS NULL;"
        rows = @controller.database.execute(q)

        filter_props = {}

        # For each torrent, get its properties and apply a seed limit if needed.
        rows.each do |r|
          response = utorrent.get_torrent_job_properties( r[0] )
          if (! response["props"].nil? )

            props = response["props"][0]
            seed_override = props["seed_override"]
            seed_ratio = props["seed_ratio"]
            raw_trackers = props["trackers"]

            if (seed_override != 1)   # Don't bother if an override is already set.

              # Break the list of trackers into individual strings and load the filters (if any).
              trackers = raw_trackers.split("\r\n")
              filters = cfg[:filters]

              # Check each tracker against all filters looking for a match.
              if (! trackers.nil? && trackers.length > 0 )
                if (! filters.nil? && filters.length > 0 )
                  trackers.each do |tracker|
                    filters.each do |filtered_tracker, limit|
                      if ( tracker.include?(filtered_tracker) )

                        # Found a match... add it to the props list to be applied when we're finished here.
                        filter_props[r[0]] = {"seed_override" => 1, "seed_ratio" => Integer(limit)}
                        $LOG.debug "  filter criteria met: #{filtered_tracker}, #{limit}, #{r[2]}, for tracker #{tracker}"
                        log( "Applying tracker filter to #{r[2]}." )
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
          response = utorrent.set_job_properties( filter_props )
        end
    end


    ###
    # Update torrent states within the DB
    #
    def update_torrent_states()
      $LOG.debug "Processor::update_torrent_states()"

        # Get list of torrents where state = NULL
        q = "SELECT hash, percent_progress, name FROM torrents WHERE tp_state IS NULL;"
        rows = @controller.database.execute(q)

        # For each torrent where download percentage < 100, set state = STATE_DOWNLOADING
        rows.each do |r|
          if r[1] < 1000
            @controller.database.update_torrent_state(r[0], STATE_DOWNLOADING)
            log( "State set to STATE_DOWNLOADING: #{r[2]}" )
          else
            @controller.database.update_torrent_state(r[0], STATE_DOWNLOADED)
            log( "State set to STATE_DOWNLOADED: #{r[2]}" )
          end
        end

        # Get list of torrents where state = STATE_DOWNLOADING
        q = "SELECT hash, percent_progress, name FROM torrents WHERE tp_state = \"#{STATE_DOWNLOADING}\";"
        rows = @controller.database.execute(q)

        # For each torrent where download percentage = 100, set state = STATE_DOWNLOADED
        rows.each do |r|
          if r[1] >= 1000
            @controller.database.update_torrent_state(r[0], STATE_DOWNLOADED)
            log( "State set to STATE_DOWNLOADED: #{r[2]}" )
          end
        end

        # Get list of torrents where state = STATE_DOWNLOADED
        q = "SELECT hash, name FROM torrents WHERE tp_state = \"#{STATE_DOWNLOADED}\";"
        rows = @controller.database.execute(q)

        # For each torrent where state = STATE_DOWNLOADED, set state = STATE_PROCESSING
        rows.each do |r|
          @controller.database.update_torrent_state(r[0], STATE_PROCESSING)
          log( "State set to STATE_PROCESSING: #{r[1]}" )
        end

    end


    ###
    # Remove torrents from DB that have been removed from utorrent
    #
    # torrents:: torrents that have been removed
    #
    def remove_torrents(torrents)
      $LOG.debug "Processor::remove_torrents( torrents )"

        # From DB - Get list of torrents that are STATE_REMOVING
        q = "SELECT hash, name FROM torrents WHERE tp_state = \"#{STATE_REMOVING}\";"
        rows = @controller.database.execute(q)

        # For each torrent in awaiting list, remove it if the removed list contains its hash
        rows.each do |r|
          if torrents.has_key?(r[0])
            # Remove it from DB and removal list
            @controller.database.delete_torrent( r[0] )
            torrents.delete( r[0] )
            # Log it
            log( "Torrent removed (as requested): #{r[1]}" )
          end
        end

        # For remaining torrents in removal list, remove them from DB and removal list
        torrents.each do |hash, t|
          @controller.database.delete_torrent( hash )
          # Log it
          log( "Torrent removed (NOT requested): #{t.name}" )
        end

    end


    ###
    # Remove torrents from DB that have been removed from utorrent
    #
    # torrents:: current list of torrents passed from utorrent
    #
    def remove_missing_torrents(torrents)
      $LOG.debug "Processor::remove_missing_torrents( torrents )"

        log( "Removing (pending removal) torrents from DB that are no longer in the uTorrent list" )

        # From DB - Get list of torrents that are STATE_REMOVING
        q = "SELECT hash, name FROM torrents WHERE tp_state = \"#{STATE_REMOVING}\";"
        rows = @controller.database.execute(q)


        # For each torrent in awaiting list, remove it if the torrent list DOES NOT contains its hash
        removed_count = 0
        rows.each do |r|
          if !torrents.has_key?(r[0])
            # Remove it from DB
            log( "    Torrent removed from DB: #{r[1]}" )
            @controller.database.delete_torrent( r[0] )
            removed_count += 1
          end
        end

        log("    No torrents were removed.") if (removed_count < 1)
    end


    ###
    # Process torrents that are awaiting processing
    #
    def process_torrents_awaiting_processing()
      $LOG.debug "Processor::process_torrents_awaiting_processing()"

        # Get list of torrents from DB where state = STATE_PROCESSING
        q = "SELECT hash, name, folder, label FROM torrents WHERE tp_state = \"#{STATE_PROCESSING}\";"
        rows = @controller.database.execute(q)

        # For each torrent, process it
        rows.each do |r|
          torrent = { hash: r[0], filename: r[1], filedir: r[2], label: r[3] }

          log( "Processing torrent: #{torrent[:filename]} (in #{torrent[:filedir]})" )

          begin

            ProcessorPluginManager.execute_each @controller, torrent

            # For each torrent, if processed successfully (file copied), set state = processed
            @controller.database.update_torrent_state( hash, "processed" )
            log( "    Torrent processed successfully: #{torrent[:filename]}" )

          rescue ProcessorPlugin::PluginError => e

            log "    Processing aborted for torrent: #{torrent[:filename]}"
            log "      Reason: #{e.message}"

          end
        end

    end

    ###
    # Process torrents that have completed processing
    #
    def update_torrents_completed_processing()
      $LOG.debug "Processor::update_torrents_completed_processing()"

        # Get list of torrents from DB where state = processed
        q = "SELECT hash, name FROM torrents WHERE tp_state = \"processed\";"
        rows = @controller.database.execute(q)

        # For each torrent, set state = STATE_SEEDING
        rows.each do |r|
          @controller.database.update_torrent_state( r[0], STATE_SEEDING )
          log( "State set to STATE_SEEDING: #{r[1]}" )
        end

    end


    ###
    # Process torrents that have completed seeding
    #
    def process_torrents_completed_seeding()
      $LOG.debug "Processor::process_torrents_completed_seeding()"

        # Get list of torrents from DB where state = STATE_SEEDING
        q = "SELECT hash, ratio, name FROM torrents WHERE tp_state = \"#{STATE_SEEDING}\";"
        rows = @controller.database.execute(q)

        # For each torrent, if ratio >= target ratio
        rows.each do |r|
          target_ratio = get_target_seed_ratio( r[2], r[0] )
          if ( Integer(r[1]) >= target_ratio )
            # Set state = STATE_REMOVING
            @controller.database.update_torrent_state( r[0], STATE_REMOVING )
            log( "State set to STATE_REMOVING: #{r[2]}" )

            # Request removal via utorrent
            utorrent.remove_torrent( r[0] )
            log( "Removal request sent: #{r[2]}" )
          end
        end

    end


    ###
    # Determine the target seed ratio for a torrent.
    #
    def get_target_seed_ratio(name, hash)
      $LOG.debug "Processor::get_target_seed_ratio( #{name} )"
      target_ratio = TorrentProcessor.configuration.utorrent.seed_ratio
      $LOG.debug "  target_ratio set to default: #{target_ratio}"
            # This torrent may have an overridden target seed ratio.
            # Pull down the torrent job properties to check and see.
      response = utorrent.get_torrent_job_properties( hash )
      if (! response["props"].nil? )

        props = response["props"][0]
        seed_override = props["seed_override"]
        seed_ratio = props["seed_ratio"]
        if (seed_override == 1)
          target_ratio = Integer(seed_ratio)
          $LOG.debug "  target_ratio set to override value: #{target_ratio}"
          log( "Torrent [#{name}] has overridden target seed ratio" )
          log( "  target ratio = #{target_ratio}" )
        end
      end
      # Add some padding to the target ratio since the final ratio is almost
      # never exactly reached.
      # 5 = .05 percent.
      target_ratio = target_ratio - 5
    end


    ###
    # Run interactive console
    #
    def interactiveMode()
      $LOG.debug "Processor::interactiveMode"

      console = Console.new(@controller)
      console.verbose = @verbose

      console.execute
    end


    ###
    # Move completed movies to the final directory (where XBMC looks)
    #
    def move_completed_movies
      $LOG.debug "Processor::move_completed_movies"

      db = moviedb
      if !db.nil?
        mover = MovieMover.new(db, @controller)
        mover.process(cfg[:movieprocessing],
                      cfg[:target_movies_path],
                      cfg[:can_copy_start_time],
                      cfg[:can_copy_stop_time])
      end
    end
  end # class Processor
end # module TorrentProcessor
