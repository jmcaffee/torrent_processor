##############################################################################
# File::    sqlite_adapter.rb
# Purpose:: SQLite3 Database Adapter object.
#
# Author::    Jeff McAffee 2015-01-28
# Copyright:: Copyright (c) 2015, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'ktcommon/ktpath'
require 'ktcommon/ktcmdline'
require 'sqlite3'

module TorrentProcessor

  ##########################################################################
  # SqliteAdapter class
  class SqliteAdapter

    def initialize dbpath
      @dbpath = dbpath
    end

    def database
      if (@database.nil? || @database.closed?)
        @database = connect
      end
      @database
    end

    ###
    # Connect to Database
    #
    def connect
      db = SQLite3::Database.new( @dbpath )

      #$LOG.debug "  Connected to db: #{dbname}" if !db.nil?
      #$LOG.error "  Unable to connect to db: #{dbname}" if db.nil?

      raise "ERROR: Unable to connect to database: #{@dbpath}" if db.nil?

      db
    end

    ###
    # Close the Database connection
    #
    def close()
      return if @database.nil? || @database.closed?
      @database.close
      @database = nil
    end

    ###
    # Execute a read query against the DB
    #
    def read(query)
      execute(query)
    end

    ###
    # Execute an insert query against the DB
    #
    def insert(query)
      execute(query)
    end

    ###
    # Execute an update query against the DB
    #
    def update(query)
      execute(query)
    end

    ###
    # Execute a delete query against the DB
    #
    def delete(query)
      execute(query)
    end

    ###
    # Execute a query against the DB
    #
    def execute(query)
      # NOTE: execute will only execute the *first* statement in a query.
      # Use execute_batch if the query contains mulitple statements.
      rows = database.execute( query )
    end


    ###
    # Execute a batch query against the DB
    #
    def execute_batch(query)
      # NOTE: execute will only execute the *first* statement in a query.
      # Use execute_batch if the query contains mulitple statements.
      rows = database.execute_batch( query )
    end


  end # class SqliteAdapter



end # module TorrentProcessor
