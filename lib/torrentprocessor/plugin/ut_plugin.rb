##############################################################################
# File::    utplugin.rb
# Purpose:: uTorrent Plugin class.
#
# Author::    Jeff McAffee 02/21/2012
# Copyright:: Copyright (c) 2012, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

module TorrentProcessor::Plugin

  class UTPlugin
    require_relative '../service/utorrent'
    include TorrentProcessor
    include KtCmdLine

    def UTPlugin.register_cmds
      { ".testcon" =>     Command.new(UTPlugin, :ut_test_connection,  "Test the uTorrent WebUI connection"),
        ".utsettings" =>  Command.new(UTPlugin, :ut_settings,         "Grab the current uTorrent settings"),
        ".jobprops" =>    Command.new(UTPlugin, :ut_jobprops,         "Retrieve a torrent's job properties"),
        ".tlist" =>       Command.new(UTPlugin, :ut_list,             "Get a list of torrents from uTorrent"),
        ".tnames" =>      Command.new(UTPlugin, :ut_names,            "Display names of torrents in uTorrent"),
        ".tdetails" =>    Command.new(UTPlugin, :ut_torrent_details,  "Display torrent(s) details"),
        ".listquery" =>   Command.new(UTPlugin, :ut_list_query,       "Return response output of list query"),
        #"." => Command.new(UTPlugin, :, ""),
      }
    end

    ###
    # Test the webui connection
    #
    def ut_test_connection(args)
      parse_args args
      cmdtxt = args[:cmd]

      log "Attempting to connect to #{cfg.utorrent.ip}:#{cfg.utorrent.port} using login #{cfg.utorrent.user}/#{cfg.utorrent.pass}"
      log "..."

      begin
        ut = TorrentProcessor::Service::UTorrent::UTorrentWebUI.new(cfg.utorrent.ip, cfg.utorrent.port, cfg.utorrent.user, cfg.utorrent.pass)
        utorrent.send_get_query("/gui/?list=1")

      rescue Exception => e
        log
        log "* Connection attempt has failed with the following reason:"
        log
        log e.message
        log
        return true
      end

      log "Connected successfully!"
      return true
    end

    def ut_settings(args)
      parse_args args
      cmdtxt = args[:cmd]

      utorrent.get_utorrent_settings()

      Formatter.pHr
      log "  uTorrent Settings"
      Formatter.pHr
      log
      #log utorrent.settings.class
      utorrent.settings.each do |i|
        #log utorrent.settings.inspect
        log i.inspect
      end
      return true
    end

    def ut_jobprops(args)
      parse_args args
      cmdtxt = args[:cmd]

      utorrent.get_torrent_list()
      hashes = select_torrent_hashes( utorrent.torrents )
      return true if hashes.nil?

      log "  Retrieving Job Properties..."
      dump_jobprops( utorrent, hashes )
      return true
    end

    def ut_list(args)
      parse_args args

      data = utorrent.get_torrent_list()
      display_current_torrent_list( utorrent.torrents )
      log " #{utorrent.torrents.length} Torrent(s) found."
      log

      return true
    end

    def ut_names(args)
      parse_args args

      data = utorrent.get_torrent_list()
      len = utorrent.torrents.length
      if len == 0
        log "No torrents to dump"
        return true
      end

      Formatter.pHr
      log " Hash  | Name"
      #log "Torrent Names"
      Formatter.pHr
      log

      utorrent.torrents.each do |k,v|
        log "...#{k.slice(-4,4)}\t#{v.name}"
      end

      log
      Formatter.pHr
      log

      return true
    end

    ###
    # Display torrent details
    #
    def ut_torrent_details(args)
      parse_args args

      utorrent.get_torrent_list()
      hashes = select_torrent_hashes( utorrent.torrents )
      return true if hashes.nil?

      hashes.each do |torr|
        log Formatter.pHr
        hsh = torr[0]
        Formatter.pHash(utorrent.torrents[hsh].to_hsh)
      end # each torr

      log Formatter.pHr

      return true
    end

    ###
    # Return the response data from a uTorrent list query
    #
    # *Args*
    #
    # +args+ -- args passed from caller
    #
    # *Returns*
    #
    # nothing
    #
    def ut_list_query(args)
      parse_args args

      response = utorrent.get_torrent_list()
      Formatter.pHr
      log response.inspect
      Formatter.pHr

      return true
    end

  private

    def parse_args args
      args = defaults.merge(args)
      self.logger    = args[:logger]   if args[:logger]
      self.utorrent  = args[:utorrent] if args[:utorrent]
      self.database  = args[:database] if args[:database]
    end

    def defaults
      {
        :logger     => NullLogger
      }
    end

    def utorrent=(ut_obj)
      @utorrent = ut_obj
    end

    def utorrent
      @utorrent
    end

    def database=(db_obj)
      @database = db_obj
    end

    def database
      @database
    end

    def logger=(logger_obj)
      @logger = logger_obj
    end

    def log msg = ''
      @logger.log msg
    end

    def cfg
      TorrentProcessor.configuration
    end

    ###
    # Display torrent job property data
    #
    def dump_jobprops( ut, hashes )

      hashes.each do |hsh|

        thsh = hsh[0]
        tname = hsh[1]
        response = utorrent.get_torrent_job_properties( thsh )
        #log rows.inspect
        log "Name: #{tname}"

        log "Error: Not found in uTorrent." if response["props"].nil?
        return if response["props"].nil?

        tab = "  "
        log tab + "uTorrent Build: #{response["build"]}"
        log "Props:"
        props = response["props"][0]
        log tab + "hash: " + props["hash"]
        log tab + "ulrate:        " + props["ulrate"].to_s
        log tab + "dlrate:        " + props["dlrate"].to_s
        log tab + "superseed:     " + props["superseed"].to_s
        log tab + "dht:           " + props["dht"].to_s
        log tab + "pex:           " + props["pex"].to_s
        log tab + "seed_override: " + props["seed_override"].to_s
        log tab + "seed_ratio:    " + props["seed_ratio"].to_s
        log tab + "seed_time:     " + props["seed_time"].to_s
        log tab + "ulslots:       " + props["ulslots"].to_s
        log tab + "seed_num:      " + props["seed_num"].to_s
        log
        log tab + "trackers: "
        props["trackers"].split("\r\n").each do |tracker|
          log tab + tab + tracker
        end
        log
        log "------------------------------------"
        log
      end
    end

    ###
    # Display and return an indexed hash of the current torrents
    #
    # @returns hash of arrays containing torrent hash and name. The hash is keyed by 1-based index.
    #
    def display_current_torrent_list( tdata )
      len = tdata.length
      if len == 0
        log "No torrents to display"
        return nil
      end

      Formatter.pHr
      log " #  | Name"
      Formatter.pHr
      log

      # Have to build an accompanying hash because we can't fetch a value
      # from a hash using an index.
      indexed_hsh = {}
      #log "-*"*30
      #log tdata.inspect
      #log "-*"*30
      tdata.each_with_index do |(k,v),i|
        i += 1
        log "#{i}\t#{v.name}"
        indexed_hsh[i] = [v.hash, v.name]
      end

      log
      Formatter.pHr
      log

      return indexed_hsh
    end

    ###
    # Return an array containing torrent hashes and names. The data is selected by the user via index
    #
    def select_torrent_hashes( tdata )
      return [] unless tdata.size > 0

      indexed_hsh = display_current_torrent_list( tdata )
      index = getInput(" Select a torrent (0 for all, <blank> for none): ")

      # Return all torrent hashes in an array of arrays containing the hash and the name
      hashes = []
      if index == "0"
        tdata.each do |k,v|
          hashes << [v.hash, v.name]
        end
        return hashes
      end

      return nil if index.empty?

      begin
        index = Integer(index)
      rescue Exception => e
        # Handle the case where user enters text instead of a valid number.
        # We can just fall through because the Invalid Entry check below
        # will react appropriately.
      end

      if !indexed_hsh.has_key?(index)
        log " Invalid entry!"
        log
        # Re-display the list
        return select_torrent_hashes(tdata)
      end

      # Return the selected hash in an array
      return ([] << indexed_hsh[index])
    end
  end # class UTPlugin
end # module TorrentProcessor::Plugin
