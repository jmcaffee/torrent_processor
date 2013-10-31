##############################################################################
# File::    database.rb
# Purpose:: Torrent Processor Database object.
#
# Author::    Jeff McAffee 08/07/2011
# Copyright:: Copyright (c) 2011, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'ktcommon/ktpath'
require 'ktcommon/ktcmdline'
require 'sqlite3'


module TorrentProcessor

  ##########################################################################
  # Database class
  class Database
#   include KtCmdLine

    attr_reader :verbose
    attr_reader :database

    ###
    # Database constructor
    #
    # controller:: controller object
    #
    def initialize(controller)
      $LOG.debug "Database::initialize"

      @controller = controller
      @cfg        = @controller.cfg
      @verbose    = false
      @database   = nil
    end


    ###
    # Set the verbose flag
    #
    # arg:: verbose mode if true
    #
    def verbose=(arg)
      $LOG.debug "Database::verbose=( #{arg} )"
      @verbose = arg
    end


    ###
    # Connect to TP Database
    #
    def connect()
      $LOG.debug "Database::connect"
      dbname = File.join( @cfg[:appPath], "tp.db" )
      @database = SQLite3::Database.new( dbname )

      $LOG.debug "  Connected to db: #{dbname}" if !@database.nil?
      $LOG.error "  Unable to connect to db: #{dbname}" if @database.nil?
    end


    ###
    # Close the Database connection
    #
    def close()
      $LOG.debug "Database::close"
      return if @database.nil? || @database.closed?
      @database.close
    end


    ###
    # Execute a query against the DB
    #
    def execute(query)
      $LOG.debug "Database::execute( #{query} )"

      connect() if @database.nil? || @database.closed?

      # NOTE: execute will only execute the *first* statement in a query.
      # Use execute_batch if the query contains mulitple statements.
      rows = @database.execute( query )
    end


    ###
    # Execute a batch query against the DB
    #
    def execute_batch(query)
      $LOG.debug "Database::execute_batch( query )"

      connect() if @database.nil? || @database.closed?

      # NOTE: execute will only execute the *first* statement in a query.
      # Use execute_batch if the query contains mulitple statements.
      rows = @database.execute_batch( query )
    end


    ###
    # Create a torrent in the database
    #
    # torrent:: Torrent Data to update
    #
    def create(tdata)
      $LOG.debug "Database::create( tdata )"
      query = buildCreateQuery( tdata )
      return execute( query )
    end


    ###
    # Update a torrent in the database
    #
    # torrent:: Torrent Data to update
    #
    def update(tdata)
      $LOG.debug "Database::update( tdata )"
      query = buildUpdateQuery( tdata )
      return execute( query )
    end


    ###
    # Remove a torrent from the database
    #
    # hash:: Torrent hash to be removed
    #
    def delete_torrent(hash)
      $LOG.debug "Database::delete_torrent( hash )"
      query = "DELETE FROM torrents WHERE hash = \"#{hash}\";"
      return execute( query )
    end


    ###
    # Update a hash of torrents in the database
    #
    # torrents:: Hash of Torrent Data to update
    #
    def update_torrents(torrents)
      $LOG.debug "Database::update_torrents( torrents )"

      # I need to determine which torrents are updates and which are inserts.
      updates = Hash.new
      inserts = Hash.new

      torrents.each do |hash,t|
        if exists_in_db?(hash)
          updates["#{hash}"] = t
        else
          inserts["#{hash}"] = t
        end
      end

      if updates.length > 0
        query = buildBatchUpdateQuery( updates )
        execute_batch( query )
      end

      if inserts.length > 0
        query = buildBatchInsertQuery( inserts )
        #File.open("r:/tools/ruby/torrentprocessor/trunk/query.sql", 'w') {|f| f.write( query ); f.flush; }
        #puts query
        execute_batch( query )
      end
    end


    ###
    # Return true if torrent hash exists in DB
    #
    # returns:: true/false
    #
    def exists_in_db?(hash)
      $LOG.debug "Database::exists_in_db?(hash)"
      result = execute( "SELECT count() FROM torrents WHERE hash = \"#{hash}\";" )
      return false if Integer(result[0][0]) < 1
      return true
    end


    ###
    # Read a torrent's state
    #
    # returns:: state
    #
    def read_torrent_state(hash)
      $LOG.debug "Database::read_torrent_state(hash)"
      result = execute( "SELECT tp_state FROM torrents WHERE hash = \"#{hash}\";" )
      result[0]
    end


    ###
    # Update a torrents state database
    #
    # hash:: Hash of Torrent
    # state:: state of Torrent
    #
    def update_torrent_state(hash, state)
      $LOG.debug "Database::update_torrent_state( hash, state )"
      query = "UPDATE torrents SET tp_state = \"#{state}\" WHERE hash = \"#{hash}\";"
      return execute( query )
    end


    ###
    # Create the cache id
    #
    # cache_id
    #
    def create_cache(cache_id)
      $LOG.debug "Database::create_cache( #{cache_id} )"
      # Clear out the table if we're creating a new cache value.
      delete_cache()
      execute( "INSERT INTO torrents_info (cache_id) values (\"#{cache_id}\");" )
    end


    ###
    # Read the cache id
    #
    # returns:: cache_id
    #
    def read_cache()
      $LOG.debug "Database::read_cache()"
      result = execute( "SELECT cache_id FROM torrents_info WHERE id = 1;" )
      result[0][0]
    end


    ###
    # Update the cache id
    #
    # cache_id
    #
    def update_cache(cache_id)
      $LOG.debug "Database::update_cache( #{cache_id} )"
      execute( "UPDATE torrents_info SET cache_id = \"#{cache_id}\" WHERE id = 1;" )
    end


    ###
    # Delete the cache id
    #
    def delete_cache()
      $LOG.debug "Database::delete_cache()"
      execute( "DELETE FROM torrents_info;" )
    end


    ###
    # Read the application lock value
    #
    # returns:: Y or N
    #
    def read_lock()
      $LOG.debug "Database::read_lock()"
      result = execute( 'SELECT locked FROM app_lock;' )
      result[0]
    end


    ###
    # Update the application lock value
    #
    # applock:: Y or N
    #
    def update_lock(applock)
      $LOG.debug "Database::update_lock( #{applock} )"
      execute( "UPDATE app_lock SET locked = \"#{applock}\" WHERE id = 1;" )
    end


    ###
    # Aquire lock
    #
    def aquire_lock()
      $LOG.debug "Database::aquire_lock()"
      begin
        @database.transaction(:exclusive) do |d|
          result = d.execute( 'SELECT locked FROM app_lock;' )
          if result[0] == 'Y'
            throw "Already Locked"
          end
          d.execute( "UPDATE app_lock SET locked = 'Y' WHERE id = 1;" )
        end

      rescue Exception => e
        puts "Error: #{e.message}"
        return false
      end

      return true
    end


    ###
    # Release lock
    #
    def release_lock()
      $LOG.debug "Database::release_lock()"
      begin
        #execute( "BEGIN EXCLUSIVE TRANSACTION;" )
        @database.transaction(:exclusive) do |d|
          result = d.execute( 'SELECT locked FROM app_lock;' )
          if result[0] == 'N'
            return false
          end
          d.execute( "UPDATE app_lock SET locked = 'N' WHERE id = 1;" )
        end

      rescue Exception => e
        puts "Error: #{e.message}"
        return false
      end

      return true
    end


    ###
    # Build an UPDATE query using data from a TorrentData object
    #
    # tdata:: TorrentData object
    #
    def buildUpdateQuery( tdata )
      $LOG.debug "Database::buildUpdateQuery( tdata )"

      query = <<EOQ
UPDATE torrents SET
  status            = #{tdata.status},
  percent_progress  = #{tdata.percent_progress},
  ratio             = #{tdata.ratio},
  label             = "#{tdata.label}",
  msg               = "#{tdata.msg}",
  folder            = "#{tdata.folder}"
WHERE hash = "#{tdata.hash}";

EOQ
    end


    ###
    # Build a batch UPDATE query using torrent data from a Hash object
    #
    # torrents:: Hash of TorrentData objects
    #
    def buildBatchUpdateQuery( torrents )
      $LOG.debug "Database::buildBatchUpdateQuery( torrents )"

      query = "BEGIN;\n"
      torrents.each do |k,v|
        query += buildUpdateQuery( v )
      end
      query += "\nEND;"
      return query
    end


    ###
    # Build a batch INSERT query using torrent data from a Hash object
    #
    # torrents:: Hash of TorrentData objects
    #
    def buildBatchInsertQuery( torrents )
      $LOG.debug "Database::buildBatchInsertQuery( torrents )"

      query = "BEGIN;\n"
      torrents.each do |k,v|
        query += buildCreateQuery( v )
      end
      query += "\nEND;"
      return query
    end


    ###
    # Build a CREATE query using data from a TorrentData object
    #
    # tdata:: TorrentData object
    #
    def buildCreateQuery( tdata )
      $LOG.debug "Database::buildCreateQuery( tdata )"

      query = <<EOQ
INSERT INTO torrents (
  hash,
  status,
  name,
  percent_progress,
  ratio,
  label,
  msg,
  folder
)
values ("#{tdata.hash}", #{tdata.status}, "#{tdata.name}", #{tdata.percent_progress}, #{tdata.ratio}, "#{tdata.label}", "#{tdata.msg}", "#{tdata.folder}");

EOQ
    end


    ###
    # Build an INSERT OR REPLACE query using data from a TorrentData object
    #
    # tdata:: TorrentData object
    #
    def buildInsertOrReplaceQuery( tdata )
      $LOG.debug "Database::buildInsertOrReplaceQuery( tdata )"

      query = <<EOQ
INSERT OR REPLACE INTO torrents (
  hash,
  status,
  name,
  percent_progress,
  ratio,
  label,
  msg,
  folder
)
values ("#{tdata.hash}", #{tdata.status}, "#{tdata.name}", #{tdata.percent_progress}, #{tdata.ratio}, "#{tdata.label}", "#{tdata.msg}", "#{tdata.folder}");
EOQ
    end


  end # class Database



end # module TorrentProcessor
