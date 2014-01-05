##############################################################################
# File::    dbplugin.rb
# Purpose:: Database Plugin class.
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
    # DBPlugin class
    class DBPlugin


      def DBPlugin.register_cmds
        { ".dbconnect"      => Command.new(DBPlugin, :db_connect,         "Connect to TorrentProcessor DB"),
          ".dbclose"        => Command.new(DBPlugin, :db_close,           "Close the TorrentProcessor DB connection"),
          ".update"         => Command.new(DBPlugin, :db_update,          "Clear out DB and update with fresh torrent data"),
          ".changestate"    => Command.new(DBPlugin, :db_changestate,     "Change torrent states within the DB"),
          ".ratios"         => Command.new(DBPlugin, :db_torrent_ratios,  "Display the current torrent ratios within the DB"),
          ".reconcile"      => Command.new(DBPlugin, :db_reconcile,       "Reconcile the DB with uTorrent current state (TODO)"),
          ".schema"         => Command.new(DBPlugin, :db_schema,          "Display the DB schema"),
          ".states"         => Command.new(DBPlugin, :db_torrent_states,  "Display current torrent states within the DB"),
          ".tables"         => Command.new(DBPlugin, :db_list_tables,     "Display a list of DB tables"),
          #"." => Command.new(DBPlugin, :, ""),
        }
      end


      ###
      # Open a connection to the DB
      #
      def db_connect(args)
        $LOG.debug "DBPlugin::db_connect"
        cmdtxt = args[0]
        kaller = args[1]
        db = kaller.database
        db.connect()
        puts "DB connection established"
        return true
      end


      ###
      # Close the DB connection
      #
      def db_close(args)
        $LOG.debug "DBPlugin::db_close"
        cmdtxt = args[0]
        kaller = args[1]
        db = kaller.database
        db.close()
        puts "DB closed"
        return true
      end


      ###
      # Clear all torrent data from the DB and refresh with new data from uTorrent.
      #
      def db_update(args)
        $LOG.debug "DBPlugin::db_update"
        cmdtxt = args[0]
        kaller = args[1]
        db = kaller.database
        ut = kaller.utorrent

        # Remove all torrents in DB.
        q = "SELECT hash FROM torrents;"
        rows = db.execute(q)

        # For each torrent in list, remove it
        rows.each do |r|
          db.delete_torrent( r[0] )
        end

        # Get a list of torrents.
        cacheID = db.read_cache()
        ut.get_torrent_list( cacheID )
        db.update_cache( ut.cache )

        # Update the db's list of torrents.
        db.update_torrents( ut.torrents )
        puts "DB updated"
        return true
      end


      ###
      # Update a torrent's state
      #
      def db_changestate(args)
        $LOG.debug "DBPlugin::db_changestate"
        cmdtxt = args[0]
        kaller = args[1]
        db = kaller.database

        cmd_parts = cmdtxt.split
        cmd = cmd_parts[0]
        from = cmd_parts[1]
        to = cmd_parts[2]

        if (from.nil? || to.nil?)
          puts "usage: #{cmd} FROM TO"
          puts "  FROM: stage to change from (can be NULL or null)"
          puts "  TO: stage to change to"
          return true
        end

        q = "SELECT hash, name FROM torrents WHERE tp_state = \"#{from}\";"
        q = "SELECT hash, name FROM torrents WHERE tp_state IS NULL;" if from == "NULL" || from == "null"

        #puts "Executing query: #{q} :"
        rows = db.execute( q )
        puts "Found #{rows.length} rows matching '#{from}'."

        return true unless rows.length > 0

        q = "UPDATE torrents SET tp_state = \"#{to}\" WHERE tp_state = \"#{from}\";"
        q = "UPDATE torrents SET tp_state = \"#{to}\" WHERE tp_state IS NULL;" if from == "NULL" || from == "null"

        #puts "Executing query: #{q} :"
        rows = db.execute( q )
        puts "Done. #{rows.length} affected."

        return true
      end


      ###
      # Display the current torrent ratios within the DB
      #
      def db_torrent_ratios(args)
        $LOG.debug "DBPlugin::db_torrent_ratios"
        cmdtxt = args[0]
        kaller = args[1]
        db = kaller.database

        Formatter.pHeader "ID | Ratio | Name"
        q = "SELECT id,ratio,name from torrents;"
        Formatter.pQueryResults( db.execute( q ) )
        return true
      end


      ###
      # Reconcile the DB with uTorrent current state
      #
      def db_reconcile(args)
        $LOG.debug "DBPlugin::db_reconcile"
        cmdtxt = args[0]
        kaller = args[1]
        db = kaller.database

        puts "Not implemented yet."
        return true
        Formatter.pHeader "ID | Ratio | Name"
        q = "SELECT id,ratio,name from torrents;"
        Formatter.pQueryResults( db.execute( q ) )
        return true
      end


      ###
      # Display the DB schema
      #
      def db_schema(args)
        $LOG.debug "DBPlugin::db_schema"
        cmdtxt = args[0]
        kaller = args[1]
        db = kaller.database

        cmd_parts = cmdtxt.split
        table = cmd_parts[1]

        if !table.nil?
          q = "SELECT sql FROM sqlite_master WHERE name=\"#{table}\";"
        else
          q = "SELECT sql FROM sqlite_master;"
        end

        Formatter.pHeader "Table description(s)"
        Formatter.pQueryResults( db.execute( q ) )
        return true;
      end


      ###
      # Display the current state of torrents in the DB
      #
      def db_torrent_states(args)
        $LOG.debug "DBPlugin::db_torrent_states"
        cmdtxt = args[0]
        kaller = args[1]
        db = kaller.database

        Formatter.pHeader "ID | TP State | Name"
        q = "SELECT id,tp_state,name from torrents;"
        Formatter.pQueryResults( db.execute( q ) )
        return true
      end


      ###
      # Display a list of tables within the DB
      #
      def db_list_tables(args)
        $LOG.debug "DBPlugin::db_list_tables"
        cmdtxt = args[0]
        kaller = args[1]
        db = kaller.database

        Formatter.pHeader "Tables in DB"
        q = "SELECT name from sqlite_master WHERE type = 'table' ORDER BY name;"
        Formatter.pQueryResults( db.execute( q ) )
        return true
      end


    end # class DBPlugin



  end # module Plugin

end # module TorrentProcessor
