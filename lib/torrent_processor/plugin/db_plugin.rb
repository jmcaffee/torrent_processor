##############################################################################
# File::    dbplugin.rb
# Purpose:: Database Plugin class.
#
# Author::    Jeff McAffee 02/21/2012
# Copyright:: Copyright (c) 2012, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

#require_relative '../utility/formatter'

module TorrentProcessor::Plugin

  class DBPlugin < BasePlugin

    include TorrentProcessor::Utility

    attr_reader :database

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

  protected

    def parse_args args
      @torrent_app = nil
      super

      Formatter.logger = @logger

      # Enforce expections of passed args:
      args.fetch(:database)
    end

    def defaults
      {
        :logger => NullLogger
      }
    end

  private

    def torrent_app
      @torrent_app ||= TorrentProcessor::TorrentApp.new(init_args)
    end

  public

    ###
    # Open a connection to the DB
    #
    def db_connect(args)
      cmd = args.fetch(:cmd)
      parse_args args

      database.connect
      log "DB connection established"
      return true
    end

    ###
    # Close the DB connection
    #
    def db_close(args)
      cmd = args.fetch(:cmd)
      parse_args args

      database.close()
      log "DB closed"
      return true
    end

    ###
    # Clear all torrent data from the DB and refresh
    # with new data from torrent app.
    #
    def db_update(args)
      cmd = args.fetch(:cmd)
      parse_args args

      # Remove all torrents in DB.
      q = "SELECT hash FROM torrents;"
      rows = database.read(q)

      # For each torrent in list, remove it
      rows.each do |r|
        database.delete_torrent( r[0] )
      end

      # Get a list of torrents and
      # update the db's list of torrents.
      database.update_torrents( torrent_app.torrent_list )
      log "DB updated"
      return true
    end

    ###
    # Update a torrent's state
    #
    def db_changestate(args)
      cmd = args.fetch(:cmd)
      parse_args args

      cmd_parts = cmd.split
      cmd = cmd_parts[0]
      from = cmd_parts[1]
      to = cmd_parts[2]
      id = cmd_parts[3] if cmd_parts.size >= 4

      if (from.nil? || to.nil?)
        log "usage: #{cmd} FROM TO [ID]"
        log "  FROM: stage to change from (can be NULL or null)"
        log "  TO: stage to change to"
        log "  ID: ID of torrent to update - if not provided, all torrents matching the"
        log "      FROM state will be modified"
        log
        log "  Available States:"
        log "    NULL"
        log "    downloading"
        log "    downloaded"
        log "    processing"
        log "    seeding"
        log "    removing"
        log
        return true
      end

      and_id = " AND id = #{id}" if !id.nil?
      and_id ||= ''

      q = "SELECT hash, name FROM torrents WHERE (tp_state = \"#{from}\"#{and_id});"
      q = "SELECT hash, name FROM torrents WHERE (tp_state IS NULL#{and_id});" if from == "NULL" || from == "null"

      #log "Executing query: #{q} :"
      rows = database.read( q )
      log "Found #{rows.length} rows matching '#{from}'#{and_id}."

      return true unless rows.length > 0

      q = "UPDATE torrents SET tp_state = \"#{to}\" WHERE (tp_state = \"#{from}\"#{and_id});"
      q = "UPDATE torrents SET tp_state = \"#{to}\" WHERE (tp_state IS NULL#{and_id});" if from == "NULL" || from == "null"

      #log "Executing query: #{q} :"
      rows = database.execute( q )
      log "Done. #{rows.length} affected."

      return true
    end


    ###
    # Display the current torrent ratios within the DB
    #
    def db_torrent_ratios(args)
      cmd = args.fetch(:cmd)
      parse_args args

      Formatter.print_header "ID | Ratio | Name"
      q = "SELECT id,ratio,name from torrents;"
      Formatter.print_query_results( database.read( q ) )
      return true
    end


    ###
    # Reconcile the DB with uTorrent current state
    #
    def db_reconcile(args)
      cmd = args.fetch(:cmd)
      parse_args args

      log "Not implemented yet."
      return true
    end


    ###
    # Display the DB schema
    #
    def db_schema(args)
      cmd = args.fetch(:cmd)
      parse_args args

      cmd_parts = cmd.split
      table = cmd_parts[1]

      if !table.nil?
        q = "SELECT sql FROM sqlite_master WHERE name=\"#{table}\";"
      else
        q = "SELECT sql FROM sqlite_master;"
      end

      Formatter.print_header "Table description(s)"
      Formatter.print_query_results( database.read( q ) )
      return true;
    end


    ###
    # Display the current state of torrents in the DB
    #
    def db_torrent_states(args)
      cmd = args.fetch(:cmd)
      parse_args args

      Formatter.print_header "ID | TP State | Name"
      q = "SELECT id,tp_state,name from torrents;"
      Formatter.print_query_results( database.read( q ) )
      return true
    end


    ###
    # Display a list of tables within the DB
    #
    def db_list_tables(args)
      cmd = args.fetch(:cmd)
      parse_args args

      Formatter.print_header "Tables in DB"
      q = "SELECT name from sqlite_master WHERE type = 'table' ORDER BY name;"
      Formatter.print_query_results( database.read( q ) )
      return true
    end

    ###
    # Run DB upgrade migrations
    #
    def db_upgrade_db(args)
      cmd = args.fetch(:cmd)
      parse_args args

      Formatter.print_header "Run all DB migrations"
      database.upgrade
      return true
    end
  end # class DBPlugin
end # module TorrentProcessor::Plugin
