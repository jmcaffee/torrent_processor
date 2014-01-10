##############################################################################
# File::    utplugin.rb
# Purpose:: uTorrent Plugin class.
#
# Author::    Jeff McAffee 02/21/2012
# Copyright:: Copyright (c) 2012, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

##########################################################################
# TorrentProcessor module
module TorrentProcessor



  ##########################################################################
  # Plugin module
  module Plugin



    ##########################################################################
    # UTPlugin class
    class UTPlugin
      require_relative '../service/utorrent'
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
        $LOG.debug "UTPlugin::ut_test_connection"
        cmdtxt = args[0]
        kaller = args[1]
        ctrl = kaller.controller

        puts "Attempting to connect to #{ctrl.cfg[:ip]}:#{ctrl.cfg[:port]} using login #{ctrl.cfg[:user]}/#{ctrl.cfg[:pass]}"
        puts "..."

        begin
          ut = TorrentProcessor::Service::UTorrentWebUI.new(ctrl.cfg[:ip], ctrl.cfg[:port], ctrl.cfg[:user], ctrl.cfg[:pass])
          ut.sendGetQuery("/gui/?list=1")

        rescue Exception => e
          puts
          puts "* Connection attempt has failed with the following reason:"
          puts
          puts e.message
          puts
          return true
        end

        puts "Connected successfully!"
        return true
      end


      def ut_settings(args)
        $LOG.debug "UTPlugin::ut_settings"
        cmdtxt = args[0]
        kaller = args[1]
        ut = kaller.utorrent

        ut.get_utorrent_settings()
        response = ut.parseResponse()
        Formatter.pHr
        puts "  uTorrent Settings"
        Formatter.pHr
        puts
        #puts ut.settings.class
        ut.settings.each do |i|
          #puts ut.settings.inspect
          puts i.inspect
        end
        return true
      end


      def ut_jobprops(args)
        $LOG.debug "UTPlugin::ut_jobprops"
        cmdtxt = args[0]
        kaller = args[1]
        db = kaller.database
        ut = kaller.utorrent

        cmd_parts = cmdtxt.split
        cmd = cmd_parts[0]

        ut.get_torrent_list()
        hashes = select_torrent_hashes( ut.torrents )
        return true if hashes.nil?

        puts "  Retrieving Job Properties..."
        dump_jobprops( ut, hashes )
        return true
      end


      def ut_list(args)
        $LOG.debug "UTPlugin::ut_list"
        cmdtxt = args[0]
        kaller = args[1]
        ut = kaller.utorrent

        data = ut.get_torrent_list()
        display_current_torrent_list( ut.torrents )
        #puts data
        puts " #{ut.torrents.length} Torrent(s) found."
        puts

        return true
      end


      def ut_names(args)
        $LOG.debug "UTPlugin::ut_names"
        cmdtxt = args[0]
        kaller = args[1]
        ut = kaller.utorrent

        data = ut.get_torrent_list()
        len = ut.torrents.length
        if len == 0
          puts "No torrents to dump"
          return true
        end

        Formatter.pHr
        puts " Hash  | Name"
        #puts "Torrent Names"
        Formatter.pHr
        puts

        ut.torrents.each do |k,v|
          puts "...#{k.slice(-4,4)}\t#{v.name}"
        end

        puts
        Formatter.pHr
        puts

        return true
      end


      ###
      # Display torrent details
      #
      def ut_torrent_details(args)
        $LOG.debug "UTPlugin::ut_torrent_details"
        cmdtxt = args[0]
        kaller = args[1]
        ut = kaller.utorrent

        ut.get_torrent_list()
        hashes = select_torrent_hashes( ut.torrents )
        return true if hashes.nil?

        hashes.each do |torr|
          puts Formatter.pHr
          hsh = torr[0]
          Formatter.pHash(ut.torrents[hsh].to_hsh)
        end # each torr

        puts Formatter.pHr

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
        $LOG.debug "UTPlugin::ut_list_query"
        cmdtxt = args[0]
        kaller = args[1]
        ut = kaller.utorrent

        response = ut.get_torrent_list()
        Formatter.pHr
        puts response.inspect
        Formatter.pHr

        return true
      end


      ###
      # Display torrent job property data
      #
      def dump_jobprops( ut, hashes )

        hashes.each do |hsh|

          thsh = hsh[0]
          tname = hsh[1]
          response = ut.get_torrent_job_properties( thsh )
          #puts rows.inspect
          puts "Name: #{tname}"

          puts "Error: Not found in uTorrent." if response["props"].nil?
          return if response["props"].nil?

          tab = "  "
          puts tab + "uTorrent Build: #{response["build"]}"
          puts "Props:"
          props = response["props"][0]
          puts tab + "hash: " + props["hash"]
          puts tab + "ulrate:        " + props["ulrate"].to_s
          puts tab + "dlrate:        " + props["dlrate"].to_s
          puts tab + "superseed:     " + props["superseed"].to_s
          puts tab + "dht:           " + props["dht"].to_s
          puts tab + "pex:           " + props["pex"].to_s
          puts tab + "seed_override: " + props["seed_override"].to_s
          puts tab + "seed_ratio:    " + props["seed_ratio"].to_s
          puts tab + "seed_time:     " + props["seed_time"].to_s
          puts tab + "ulslots:       " + props["ulslots"].to_s
          puts tab + "seed_num:      " + props["seed_num"].to_s
          puts
          puts tab + "trackers: "
          props["trackers"].split("\r\n").each do |tracker|
            puts tab + tab + tracker
          end
          puts
          puts "------------------------------------"
          puts
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
          puts "No torrents to display"
          return nil
        end

        Formatter.pHr
        puts " #  | Name"
        Formatter.pHr
        puts

        # Have to build an accompanying hash because we can't fetch a value
        # from a hash using an index.
        indexed_hsh = {}
        #puts "-*"*30
        #puts tdata.inspect
        #puts "-*"*30
        tdata.each_with_index do |(k,v),i|
          i += 1
          puts "#{i}\t#{v.name}"
          indexed_hsh[i] = [v.hash, v.name]
        end

        puts
        Formatter.pHr
        puts

        return indexed_hsh
      end


      ###
      # Return an array containing torrent hashes and names. The data is selected by the user via index
      #
      def select_torrent_hashes( tdata )
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
          puts " Invalid entry!"
          puts
          # Re-display the list
          return select_torrent_hashes(tdata)
        end

        # Return the selected hash in an array
        return ([] << indexed_hsh[index])

      end
    end # class UTPlugin



  end # module Plugin

end # module TorrentProcessor
