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

    def filename= fname
      @filename = fname
    end

    def filename
      @filename ||= 'tp.db'
    end

    def database
      if (@database.nil? || @database.closed?)
        @database = connect
      end
      @database
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
      dbname = File.join( @cfg[:appPath], filename )
      db = SQLite3::Database.new( dbname )

      $LOG.debug "  Connected to db: #{dbname}" if !db.nil?
      $LOG.error "  Unable to connect to db: #{dbname}" if db.nil?

      unless db.nil?
        #upgrade
      end
      db
    end


    ###
    # Close the Database connection
    #
    def close()
      $LOG.debug "Database::close"
      return if @database.nil? || @database.closed?
      @database.close
      @database = nil
    end

    def create_database
      Schema.create_base_schema self
    end

    def schema_version
      # Returns the first element of the first row of the result.
      return execute('PRAGMA user_version;')[0][0]
    end

    ###
    # Update the DB if needed
    #
    def upgrade
      $LOG.debug "Database::upgrade"


      # NOTE: execute will only execute the *first* statement in a query.
      # Use execute_batch if the query contains mulitple statements.
      rows = database.execute( query )
    end

    ###
    # Execute a query against the DB
    #
    def execute(query)
      $LOG.debug "Database::execute( #{query} )"

      # NOTE: execute will only execute the *first* statement in a query.
      # Use execute_batch if the query contains mulitple statements.
      rows = database.execute( query )
    end


    ###
    # Execute a batch query against the DB
    #
    def execute_batch(query)
      $LOG.debug "Database::execute_batch( query )"

      # NOTE: execute will only execute the *first* statement in a query.
      # Use execute_batch if the query contains mulitple statements.
      rows = database.execute_batch( query )
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
        $LOG.info query
        execute_batch( query )
      end

      if inserts.length > 0
        query = buildBatchInsertQuery( inserts )
        #File.open("r:/tools/ruby/torrentprocessor/trunk/query.sql", 'w') {|f| f.write( query ); f.flush; }
        #puts query
        $LOG.info query
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
    # Build an UPDATE query using data from a TorrentData object
    #
    # tdata:: TorrentData object
    #
    def buildUpdateQuery( tdata )
      $LOG.debug "Database::buildUpdateQuery( tdata )"

      query = <<EOQ
UPDATE torrents SET
  name              = "#{tdata.name}",
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


    class Schema
      def self.create_base_schema( db )
        schema = <<EOQ
-- Create the torrents table
CREATE TABLE IF NOT EXISTS torrents (
  id INTEGER PRIMARY KEY,
  hash TEXT UNIQUE,
  created DATE,
  modified DATE,
  status NUMERIC,
  name TEXT,
  percent_progress NUMERIC,
  ratio NUMERIC,
  label TEXT,
  msg TEXT,
  folder TEXT,
  tp_state TEXT DEFAULT NULL
);

--  Create an update trigger
CREATE TRIGGER IF NOT EXISTS update_torrents AFTER UPDATE  ON torrents
BEGIN

UPDATE torrents SET modified = DATETIME('NOW')
         WHERE rowid = NEW.rowid;

END;

--  Also create an insert trigger
--    Note  AFTER keyword --------------------v
CREATE TRIGGER IF NOT EXISTS insert_torrents AFTER INSERT ON torrents
BEGIN

UPDATE torrents SET created = DATETIME('NOW')
         WHERE rowid = NEW.rowid;

UPDATE torrents SET modified = DATETIME('NOW')
         WHERE rowid = NEW.rowid;

END;

-- Create the torrents_info table
CREATE TABLE IF NOT EXISTS torrents_info (
  id INTEGER PRIMARY KEY,
  cache_id TEXT,
  created DATE,
  modified DATE
);

--  Create an update trigger
CREATE TRIGGER IF NOT EXISTS update_torrents_info AFTER UPDATE  ON torrents_info
BEGIN

UPDATE torrents_info SET modified = DATETIME('NOW')
         WHERE rowid = NEW.rowid;

END;

--  Also create an insert trigger
--    NOTE  AFTER keyword --------------------------v
CREATE TRIGGER IF NOT EXISTS insert_torrents_info AFTER INSERT ON torrents_info
BEGIN

UPDATE torrents_info SET created = DATETIME('NOW')
         WHERE rowid = NEW.rowid;

UPDATE torrents_info SET modified = DATETIME('NOW')
         WHERE rowid = NEW.rowid;

END;

-- Insert a cache record as part of initialization
INSERT INTO torrents_info (cache_id) values (NULL);

-- Create the app_lock table
CREATE TABLE IF NOT EXISTS app_lock (
  id INTEGER PRIMARY KEY,
  locked TEXT
);

-- Insert a lock record as part of initialization
INSERT INTO app_lock (locked) values ("N");
EOQ
        db.execute_batch( schema )
      end

      def self.upgrade_1(db)
        ver = db.schema_version
        return if ver >= 1

        result = db.execute('DROP TABLE IF EXISTS app_lock;')

        q = 'UPDATE torrents SET tp_state = "downloaded" WHERE tp_state = "download complete";'
        result = db.execute q

        db.execute('PRAGMA user_version = 1;')
      end
    end # class
  end # class Database



end # module TorrentProcessor
