##############################################################################
# File::    dbplugin.rb
# Purpose:: Database Plugin class.
#
# Author::    Jeff McAffee 02/21/2012
# Copyright:: Copyright (c) 2012, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require_relative '../utility/formatter'

module TorrentProcessor::Plugin

  class DBPlugin

    include TorrentProcessor::Utility

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
        ".upgrade"        => Command.new(DBPlugin, :db_upgrade_db,      "Run DB upgrade migrations"),
        #"." => Command.new(DBPlugin, :, ""),
      }
    end


    ###
    # Open a connection to the DB
    #
    def db_connect(args)
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
      cmdtxt = args[0]
      kaller = args[1]
      db = kaller.database

      cmd_parts = cmdtxt.split
      cmd = cmd_parts[0]
      from = cmd_parts[1]
      to = cmd_parts[2]
      id = cmd_parts[3] if cmd_parts.size >= 4

      if (from.nil? || to.nil?)
        puts "usage: #{cmd} FROM TO [ID]"
        puts "  FROM: stage to change from (can be NULL or null)"
        puts "  TO: stage to change to"
        puts "  ID: ID of torrent to update - if not provided, all torrents matching the"
        puts "      FROM state will be modified"
        puts
        puts "  Available States:"
        puts "    NULL"
        puts "    downloading"
        puts "    downloaded"
        puts "    processing"
        puts "    seeding"
        puts "    removing"
        puts
        return true
      end

      and_id = " AND id = #{id}" if !id.nil?
      and_id ||= ''

      q = "SELECT hash, name FROM torrents WHERE (tp_state = \"#{from}\"#{and_id});"
      q = "SELECT hash, name FROM torrents WHERE (tp_state IS NULL#{and_id});" if from == "NULL" || from == "null"

      #puts "Executing query: #{q} :"
      rows = db.execute( q )
      puts "Found #{rows.length} rows matching '#{from}'#{and_id}."

      return true unless rows.length > 0

      q = "UPDATE torrents SET tp_state = \"#{to}\" WHERE (tp_state = \"#{from}\"#{and_id});"
      q = "UPDATE torrents SET tp_state = \"#{to}\" WHERE (tp_state IS NULL#{and_id});" if from == "NULL" || from == "null"

      #puts "Executing query: #{q} :"
      rows = db.execute( q )
      puts "Done. #{rows.length} affected."

      return true
    end


    ###
    # Display the current torrent ratios within the DB
    #
    def db_torrent_ratios(args)
      cmdtxt = args[0]
      kaller = args[1]
      db = kaller.database

      Formatter.print_header "ID | Ratio | Name"
      q = "SELECT id,ratio,name from torrents;"
      Formatter.print_query_results( db.execute( q ) )
      return true
    end


    ###
    # Reconcile the DB with uTorrent current state
    #
    def db_reconcile(args)
      cmdtxt = args[0]
      kaller = args[1]
      db = kaller.database

      puts "Not implemented yet."
      return true
      Formatter.print_header "ID | Ratio | Name"
      q = "SELECT id,ratio,name from torrents;"
      Formatter.print_query_results( db.execute( q ) )
      return true
    end


    ###
    # Display the DB schema
    #
    def db_schema(args)
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

      Formatter.print_header "Table description(s)"
      Formatter.print_query_results( db.execute( q ) )
      return true;
    end


    ###
    # Display the current state of torrents in the DB
    #
    def db_torrent_states(args)
      cmdtxt = args[0]
      kaller = args[1]
      db = kaller.database

      Formatter.print_header "ID | TP State | Name"
      q = "SELECT id,tp_state,name from torrents;"
      Formatter.print_query_results( db.execute( q ) )
      return true
    end


    ###
    # Display a list of tables within the DB
    #
    def db_list_tables(args)
      cmdtxt = args[0]
      kaller = args[1]
      db = kaller.database

      Formatter.print_header "Tables in DB"
      q = "SELECT name from sqlite_master WHERE type = 'table' ORDER BY name;"
      Formatter.print_query_results( db.execute( q ) )
      return true
    end

    ###
    # Run DB upgrade migrations
    #
    def db_upgrade_db(args)
      cmdtxt = args[0]
      kaller = args[1]
      db = kaller.database

      Formatter.print_header "Run all DB migrations"
      db.upgrade
      return true
    end
  end # class DBPlugin
end # module TorrentProcessor::Plugin
