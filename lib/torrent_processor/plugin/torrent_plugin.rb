##############################################################################
# File::    utplugin.rb
# Purpose:: Torrent App Plugin class.
#
# Author::    Jeff McAffee 02/21/2012
# Copyright:: Copyright (c) 2012, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'benchmark'

module TorrentProcessor
  module Plugin

  class TorrentPlugin < BasePlugin
    include TorrentProcessor
    include KtCmdLine
    include Utility

    def TorrentPlugin.register_cmds
      { ".testcon" =>     Command.new(TorrentPlugin, :cmd_test_connection,  "Test the Torrent App WebUI connection"),
        ".tsettings" =>   Command.new(TorrentPlugin, :cmd_settings,         "Grab the current Torrent App settings"),
        ".jobprops" =>    Command.new(TorrentPlugin, :cmd_jobprops,         "Retrieve a torrent's job properties"),
        ".tlist" =>       Command.new(TorrentPlugin, :cmd_list,             "Get a list of torrents from Torrent App"),
        ".tnames" =>      Command.new(TorrentPlugin, :cmd_names,            "Display names of torrents in Torrent App"),
        ".tdetails" =>    Command.new(TorrentPlugin, :cmd_torrent_details,  "Display torrent(s) details"),
        ".listquery" =>   Command.new(TorrentPlugin, :cmd_list_query,       "Return response output of list query"),
        #"." => Command.new(TorrentPlugin, :, ""),
      }
    end

    ###
    # Test the webui connection
    #
    def cmd_test_connection(args)
      parse_args args
      cmdtxt = args[:cmd]

      ip = cfg.utorrent.ip
      port = cfg.utorrent.port
      user = cfg.utorrent.user
      pass = cfg.utorrent.pass

      if cfg.backend == :qbtorrent
        ip = cfg.qbtorrent.ip
        port = cfg.qbtorrent.port
        user = cfg.qbtorrent.user
        pass = cfg.qbtorrent.pass
      end

      log "Attempting to connect to #{ip}:#{port} using login #{user}/#{pass}"
      log "..."

      begin
        torrent_app.torrent_list

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

    def cmd_settings(args)
      parse_args args
      cmdtxt = args[:cmd]

      torrent_app.settings

      Formatter.print_rule
      log "  Torrent App Settings"
      Formatter.print_rule
      log
      #log torrent_app.settings.class
      torrent_app.settings.each do |i|
        #log torrent_app.settings.inspect
        log i.inspect
      end
      return true
    end

    def cmd_jobprops(args)
      parse_args args
      cmdtxt = args[:cmd]

      torrent_app.torrent_list
      hashes = select_torrent_hashes( torrent_app.torrents )
      return true if hashes.nil?

      log "  Retrieving Job Properties..."
      dump_jobprops( hashes )
      return true
    end

    def cmd_list(args)
      parse_args args

      data = torrent_app.torrent_list
      display_current_torrent_list( torrent_app.torrents )
      log " #{torrent_app.torrents.length} Torrent(s) found."
      log

      return true
    end

    def cmd_names(args)
      parse_args args

      data = torrent_app.torrent_list
      len = torrent_app.torrents.length
      if len == 0
        log "No torrents to dump"
        return true
      end

      Formatter.print_rule
      log " Hash  | Name"
      #log "Torrent Names"
      Formatter.print_rule
      log

      torrent_app.torrents.each do |k,v|
        log "...#{k.slice(-4,4)}\t#{v.name}"
      end

      log
      Formatter.print_rule
      log

      return true
    end

    ###
    # Display torrent details
    #
    def cmd_torrent_details(args)
      parse_args args

      torrent_app.torrent_list
      hashes = select_torrent_hashes( torrent_app.torrents )
      return true if hashes.nil?

      hashes.each do |torr|
        log Formatter.print_rule
        hsh = torr[0]
        Formatter.print(torrent_app.torrents[hsh].to_hsh)
      end # each torr

      log Formatter.print_rule

      return true
    end

    ###
    # Return the response data from a Torrent App list query
    #
    # *Args*
    #
    # +args+ -- args passed from caller
    #
    # *Returns*
    #
    # nothing
    #
    def cmd_list_query(args)
      parse_args args

      response = torrent_app.torrent_list
      Formatter.print_rule
      log response.inspect
      Formatter.print_rule

      return true
    end

  protected

    def parse_args args
      @torrent_app = nil
      super

      if args[:logger]
        Formatter.logger = args[:logger]
      end
    end

    def defaults
      {
        :cfg     => cfg
      }
    end

  private

    def torrent_app
      @torrent_app ||= TorrentApp.new(init_args)
    end

    def cfg
      TorrentProcessor.configuration
    end

    ###
    # Display torrent job property data
    #
    def dump_jobprops( hashes )

      hashes.each do |hsh|
        torrent_app.dump_job_properties hsh[0]
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

      Formatter.print_rule
      log " #  | Name"
      Formatter.print_rule
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
      Formatter.print_rule
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
  end # class
  end # module
end # module
