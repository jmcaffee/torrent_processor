##############################################################################
# File::    jdbc_adapter.rb
# Purpose:: JDBC/SQLite3 Database Adapter object.
#
# Author::    Jeff McAffee 2015-01-28
# Copyright:: Copyright (c) 2015, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'ktcommon/ktpath'
require 'ktcommon/ktcmdline'
require 'dbi'
require 'dbd/Jdbc'
require 'jdbc/sqlite3'
Jdbc::SQLite3.load_driver

module TorrentProcessor

  ##########################################################################
  # JdbcAdapter class
  class JdbcAdapter

    def initialize dbpath
      @dbpath = dbpath
    end

    def database
      if @database.nil?
        @database = connect
      end
      @database
    end

    ###
    # Connect to Database
    #
    def connect
      db = DBI.connect(
        "DBI:Jdbc:sqlite:#{@dbpath}",    # connection string
        '',                             # no username for sqlite3
        '',                             # no password for sqlite3
        'driver' => 'org.sqlite.JDBC')  # need to set the driver

      db
    end

    ###
    # Close the Database connection
    #
    def close()
      return if @database.nil?
      @database.disconnect
      @database = nil
    end

    ###
    # Execute a read query against the DB
    #
    def read(query)
      statement = database.execute(query)
      rows = []
      # Apparently DBI fetch_all and fetch are f'd up.
      # When returning items, they return them as references instead
      # of values, so adding items to an array changes the items that
      # were previously added to the array as well.
      # TL;DR: use fetch_hash
      statement.fetch_hash do |r|
        rows << r.values
      end
      statement.finish
      rows
    end

    ###
    # Execute an insert query against the DB
    #
    def insert(query)
      rows = 0
      database['AutoCommit'] = false
      begin
        statement = database.prepare(query)
        statement.execute
        rows = statement.rows
        statement.finish
        database.commit
      rescue DBI::DatabaseError => e
        puts "ERROR:"
        puts "Code: #{e.err}"
        puts "Msg:  #{e.errstr}"
        database.rollback
      end
      database['AutoCommit'] = true

      rows
    end

    ###
    # Execute an update query against the DB
    #
    def update(query)
      rows = 0
      database['AutoCommit'] = false
      begin
        statement = database.prepare(query)
        statement.execute
        rows = statement.rows
        statement.finish
        database.commit
      rescue DBI::DatabaseError => e
        puts "ERROR:"
        puts "Code: #{e.err}"
        puts "Msg:  #{e.errstr}"
        database.rollback
      end
      database['AutoCommit'] = true

      rows
    end

    ###
    # Execute a delete query against the DB
    #
    def delete(query)
      rows = 0
      database['AutoCommit'] = false
      begin
        statement = database.prepare(query)
        statement.execute
        rows = statement.rows
        statement.finish
        database.commit
      rescue DBI::DatabaseError => e
        puts "ERROR:"
        puts "Code: #{e.err}"
        puts "Msg:  #{e.errstr}"
        database.rollback
      end
      database['AutoCommit'] = true

      rows
    end

    ###
    # Execute a query against the DB
    #
    def execute(query)
      statement = database.execute(query)
      rows = []
      # See #read for info about broken ass
      # statement#fetch and friends.
      statement.fetch_hash do |r|
        rows << r.values
      end
      statement.finish
      rows
    end


    ###
    # Execute a batch query against the DB
    #
    def execute_batch(query)
      statement = database.execute(query)
      rows = []
      # See #read for info about broken ass
      # statement#fetch and friends.
      statement.fetch_hash do |r|
        rows << r.values
      end
      statement.finish
      rows
    end


  end # class JdbcAdapter



end # module TorrentProcessor
