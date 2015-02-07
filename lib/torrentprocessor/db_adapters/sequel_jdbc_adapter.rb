##############################################################################
# File::    sequel_jdbc_adapter.rb
# Purpose:: JDBC/SQLite3 Database Adapter object.
#
# Author::    Jeff McAffee 2015-01-28
# Copyright:: Copyright (c) 2015, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'ktcommon/ktpath'
require 'ktcommon/ktcmdline'
require 'sequel'
require 'jdbc/sqlite3'
Jdbc::SQLite3.load_driver

module TorrentProcessor

  ##########################################################################
  # SequelJdbcAdapter class
  class SequelJdbcAdapter

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
      db = Sequel.connect(
        "jdbc:sqlite:#{@dbpath}")
    end

    ###
    # Close the Database connection
    #
    def close()
      return if @database.nil?
      @database.disconnect
      @database = nil
    end

    def closed?
      return true if @database.nil?
      return false
    end

    ###
    # Execute a read query against the DB
    #
    def read(query)
      rows = []
      database.fetch(query) do |row|
        rows << row.values
      end
      rows
    end

    ###
    # Execute an insert query against the DB
    #
    def insert(query)
      insert_ds = database[query]
      insert_ds.insert
    end

    ###
    # Execute an update query against the DB
    #
    def update(query)
      update_ds = database[query]
      update_ds.update
    end

    ###
    # Execute a delete query against the DB
    #
    def delete(query)
      delete_ds = database[query]
      delete_ds.delete
    end

    ###
    # Execute a query against the DB
    #
    def execute(query)
      rows = []
      database.fetch(query) do |row|
        rows << row.values
      end

      rows
    rescue Sequel::DatabaseError => e #Java::JavaSql::SQLException => e
      # If we get the appropriate exception, there are no rows to return
      if ! e.wrapped_exception.to_s.include?('query does not return ResultSet')
        raise e
      end
      []
    end


    ###
    # Execute a batch query against the DB
    #
    # queries: array of query statements
    def execute_batch(queries)
      database.transaction do
        Array(queries).each do |query|
          database.run(query)
        end
      end
    end


  end # class SequelJdbcAdapter



end # module TorrentProcessor
