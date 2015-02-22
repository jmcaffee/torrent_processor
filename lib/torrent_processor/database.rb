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


module TorrentProcessor

  ##########################################################################
  # Database class
  class Database
   include Utility::Loggable
   include Utility::Verbosable

    attr_reader :cfg
    attr_accessor :filename
    attr_accessor :filepath

    ###
    # Database constructor
    #
    # controller:: controller object
    #
    def initialize(args)
      parse_args args

      @database   = nil
      @adapter    = nil
    end

    def parse_args args
      args = defaults.merge(args)
      @cfg = args[:cfg] if args[:cfg]
      @verbose = args[:verbose] if args[:verbose]
      @logger = args[:logger] if args[:logger]
    end

    def defaults
      {
        #:logger => NullLogger,
        #:verbose => false,
      }
    end

    def filename
      @filename ||= 'tp.db'
    end

    def filepath
      @filepath ||= File.join( cfg.app_path, filename )
    end

    def adapter
      return @adapter unless @adapter.nil?

      if defined?(JRUBY_VERSION)
        #require_relative 'db_adapters/jdbc_adapter'
        #@adapter    = JdbcAdapter.new filepath
        log 'DB: Initializing SequelJdbcAdapter' if verbose
        require_relative 'db_adapters/sequel_jdbc_adapter'
        @adapter    = SequelJdbcAdapter.new filepath
      else
        log 'DB: Initializing SqliteAdapter' if verbose
        require_relative 'db_adapters/sqlite_adapter'
        @adapter    = SqliteAdapter.new filepath
      end
    end

    def database
      adapter.database
    end


    ###
    # Connect to TP Database
    #
    def connect()
      log "DB: Connecting to #{filepath}" if verbose
      adapter.connect
    end


    ###
    # Close the Database connection
    #
    def close()
      log 'DB: Closing database' if verbose
      adapter.close
    end

    def closed?
      adapter.closed?
    end

    def create_database
      log 'DB: Creating database' if verbose
      Schema.create_base_schema self
    end

    def schema_version
      # Returns the first element of the first row of the result.
      return (adapter.execute('PRAGMA user_version;')[0][0]).to_i
    end

    def drop_all
      tables = read "SELECT name from sqlite_master WHERE type = 'table' ORDER BY name;"
      tables.each do |t|
        log "Dropping table #{t.first}" if verbose
        execute "DROP TABLE IF EXISTS #{t.first};"
      end
    end

    ###
    # Upgrade the DB schema if needed
    #
    def upgrade
      log 'DB: Upgrading database' if verbose
      Schema.perform_migrations self
    end

    ###
    # Execute a query against the DB
    #
    def execute(query)
      # NOTE: execute will only execute the *first* statement in a query.
      # Use execute_batch if the query contains mulitple statements.
      log('DB: Executing query: ' + query) if verbose
      rows = adapter.execute( query )
    end


    ###
    # Execute a batch query against the DB
    #
    # queries: array of query statements
    #
    def execute_batch(queries)
      # NOTE: execute will only execute the *first* statement in a query.
      # Use execute_batch if the query contains mulitple statements.
      log('DB: Executing batch query: ' + queries) if verbose
      rows = adapter.execute_batch( queries )
    end


    def read(query)
      log('DB: Read: ' + query) if verbose
      adapter.read(query)
    end

    ###
    # Create a torrent in the database
    #
    # torrent:: Torrent Data to update
    #
    def create(tdata)
      query = build_create_query( tdata )
      log('DB: Create: ' + query) if verbose
      return adapter.insert( query )
    end


    ###
    # Update a torrent in the database
    #
    # torrent:: Torrent Data to update
    #
    def update(tdata)
      query = build_update_query( tdata )
      log('DB: Update: ' + query) if verbose
      return adapter.update( query )
    end


    ###
    # Remove a torrent from the database
    #
    # hash:: Torrent hash to be removed
    #
    def delete_torrent(hash)
      query = "DELETE FROM torrents WHERE hash = \"#{hash}\";"
      log('DB: Delete torrent: ' + query) if verbose
      return adapter.delete( query )
    end


    ###
    # Update a hash of torrents in the database
    #
    # torrents:: Hash of Torrent Data to update
    #
    def update_torrents(torrents)
      log 'DB: Update torrents' if verbose
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

      log "DB: #{updates.length} torrent(s) to update" if verbose
      if updates.length > 0
        query = build_batch_update_query( updates )
        log query if verbose
        adapter.execute_batch( query )
      end

      log "DB: #{inserts.length} torrent(s) to insert" if verbose
      if inserts.length > 0
        query = build_batch_insert_query( inserts )
        log query if verbose

        adapter.execute_batch( query )
      end
    end


    ###
    # Return true if torrent hash exists in DB
    #
    # returns:: true/false
    #
    def exists_in_db?(hash)
      result = read( "SELECT count() FROM torrents WHERE hash = \"#{hash}\";" )
      return false if Integer(result[0][0]) < 1
      return true
    end


    ###
    # Read a torrent's state
    #
    # returns:: state
    #
    def read_torrent_state(hash)
      log "DB: Read torrent state: #{hash}" if verbose
      result = adapter.read( "SELECT tp_state FROM torrents WHERE hash = \"#{hash}\";" )
      result[0]
    end


    ###
    # Update a torrents state database
    #
    # hash:: Hash of Torrent
    # state:: state of Torrent
    #
    def update_torrent_state(hash, state)
      query = "UPDATE torrents SET tp_state = \"#{state}\" WHERE hash = \"#{hash}\";"
      log "DB: Update torrent state: #{query}" if verbose
      return adapter.update( query )
    end


    ###
    # Create the cache id
    #
    # cache_id
    #
    def create_cache(cache_id)
      log "DB: Create cache: #{cache_id}" if verbose
      # Clear out the table if we're creating a new cache value.
      delete_cache()
      adapter.insert( "INSERT INTO torrents_info (cache_id) values (\"#{cache_id}\");" )
    end


    ###
    # Read the cache id
    #
    # returns:: cache_id
    #
    def read_cache()
      result = adapter.read( "SELECT cache_id FROM torrents_info WHERE id = 1;" )
      log "DB: Read cache: #{result}" if verbose
      result[0][0]
    end


    ###
    # Update the cache id
    #
    # cache_id
    #
    def update_cache(cache_id)
      log "DB: Update cache: #{cache_id}" if verbose
      adapter.update( "UPDATE torrents_info SET cache_id = \"#{cache_id}\" WHERE id = 1;" )
    end


    ###
    # Delete the cache id
    #
    def delete_cache()
      log "DB: Delete cache" if verbose
      adapter.delete( "DELETE FROM torrents_info;" )
    end


    ###
    # Build an UPDATE query using data from a TorrentData object
    #
    # tdata:: TorrentData object
    #
    def build_update_query( tdata )

      query = <<EOQ
UPDATE torrents SET
  name              = "#{tdata.name}",
  status            = "#{tdata.status}",
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
    def build_batch_update_query( torrents )
      queries = []
      torrents.each do |k,v|
        queries << build_update_query( v )
      end
      return queries
    end


    ###
    # Build a batch INSERT query using torrent data from a Hash object
    #
    # torrents:: Hash of TorrentData objects
    #
    def build_batch_insert_query( torrents )
      queries = []
      torrents.each do |k,v|
        queries << build_create_query( v )
      end
      return queries
    end


    ###
    # Build a CREATE query using data from a TorrentData object
    #
    # tdata:: TorrentData object
    #
    def build_create_query( tdata )
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
values ("#{tdata.hash}", "#{tdata.status}", "#{tdata.name}", #{tdata.percent_progress}, #{tdata.ratio}, "#{tdata.label}", "#{tdata.msg}", "#{tdata.folder}");

EOQ
    end


    ###
    # Build an INSERT OR REPLACE query using data from a TorrentData object
    #
    # tdata:: TorrentData object
    #
    def buildInsertOrReplaceQuery( tdata )
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
values ("#{tdata.hash}", "#{tdata.status}", "#{tdata.name}", #{tdata.percent_progress}, #{tdata.ratio}, "#{tdata.label}", "#{tdata.msg}", "#{tdata.folder}");
EOQ
    end

    def find_torrent_by_id id
      q = "SELECT * FROM torrents WHERE id = #{id};"
      row = adapter.execute(q).first
      { :id               => row[0],
        :hash             => row[1],
        :created          => row[2],
        :modified         => row[3],
        :status           => row[4],
        :name             => row[5],
        :percent_progress => row[6],
        :ratio            => row[7],
        :label            => row[8],
        :msg              => row[9],
        :folder           => row[10],
        :tp_state         => row[11],
      }
    end

    class Schema
      # Update SCHEMA_VERSION when new migrations are added.
      SCHEMA_VERSION = 2 unless defined?(SCHEMA_VERSION)

      def self.create_base_schema( db )
        schema = <<EOQ
-- Create the torrents table
CREATE TABLE IF NOT EXISTS torrents (
  id INTEGER PRIMARY KEY,
  hash TEXT UNIQUE,
  created TEXT,
  modified TEXT,
  status TEXT,
  name TEXT,
  percent_progress NUMERIC,
  ratio NUMERIC,
  label TEXT,
  msg TEXT,
  folder TEXT,
  tp_state TEXT DEFAULT NULL
);
EOQ
        db.execute( schema )

#--  Create an update trigger
        schema = <<EOQ
CREATE TRIGGER IF NOT EXISTS update_torrents AFTER UPDATE  ON torrents
BEGIN

UPDATE torrents SET modified = DATETIME('NOW')
         WHERE rowid = NEW.rowid;

END;
EOQ
        db.execute( schema )

#--  Also create an insert trigger
#--    Note  AFTER keyword --------------------v
        schema = <<EOQ
CREATE TRIGGER IF NOT EXISTS insert_torrents AFTER INSERT ON torrents
BEGIN

UPDATE torrents SET created = DATETIME('NOW')
         WHERE rowid = NEW.rowid;

UPDATE torrents SET modified = DATETIME('NOW')
         WHERE rowid = NEW.rowid;

END;
EOQ
        db.execute( schema )

#-- Create the torrents_info table
        schema = <<EOQ
CREATE TABLE IF NOT EXISTS torrents_info (
  id INTEGER PRIMARY KEY,
  cache_id TEXT,
  created TEXT,
  modified TEXT
);
EOQ
        db.execute( schema )

#--  Create an update trigger
        schema = <<EOQ
CREATE TRIGGER IF NOT EXISTS update_torrents_info AFTER UPDATE  ON torrents_info
BEGIN

UPDATE torrents_info SET modified = DATETIME('NOW')
         WHERE rowid = NEW.rowid;

END;
EOQ
        db.execute( schema )

#--  Also create an insert trigger
#--    NOTE  AFTER keyword --------------------------v
        schema = <<EOQ
CREATE TRIGGER IF NOT EXISTS insert_torrents_info AFTER INSERT ON torrents_info
BEGIN

UPDATE torrents_info SET created = DATETIME('NOW')
         WHERE rowid = NEW.rowid;

UPDATE torrents_info SET modified = DATETIME('NOW')
         WHERE rowid = NEW.rowid;

END;
EOQ
        db.execute( schema )

#-- Insert a cache record as part of initialization
        schema = <<EOQ
INSERT INTO torrents_info (cache_id) values (NULL);
EOQ
        db.execute( schema )

#-- Create the app_lock table
        schema = <<EOQ
CREATE TABLE IF NOT EXISTS app_lock (
  id INTEGER PRIMARY KEY,
  locked TEXT
);
EOQ
        db.execute( schema )

#-- Insert a lock record as part of initialization
        schema = <<EOQ
INSERT INTO app_lock (locked) values ("N");
EOQ
        db.execute( schema )
      end

      def self.perform_migrations(db)
        return unless db.schema_version < SCHEMA_VERSION
        migrate_to_v2(db)
      end

      def self.migrate_to_v1(db)
        ver = db.schema_version
        return if ver >= 1
        db.log "Migrating DB to v1..." if db.verbose

        result = db.execute('DROP TABLE IF EXISTS app_lock;')

        q = 'UPDATE torrents SET tp_state = "downloaded" WHERE tp_state = "download complete";'
        result = db.execute q

        q = 'UPDATE torrents SET tp_state = "processing" WHERE tp_state = "awaiting processing";'
        result = db.execute q

        q = 'UPDATE torrents SET tp_state = "removing" WHERE tp_state = "awaiting removal";'
        result = db.execute q

        db.execute('PRAGMA user_version = 1;')
        db.log "v1 migration complete." if db.verbose
      end

      def self.migrate_to_v2(db)
        migrate_to_v1 db

        ver = db.schema_version
        return if ver >= 2
        db.log "Migrating DB to v2..." if db.verbose

        # Copy existing table to tmp table
        result = db.execute("CREATE TABLE 'new_torrents' AS SELECT * FROM 'torrents';")
        result = db.execute("DROP TABLE 'torrents';")

        # Recreate the old table, updating status column type to be text (was numeric)
        schema = <<EOQ
-- Create the torrents table
CREATE TABLE IF NOT EXISTS torrents (
  id INTEGER PRIMARY KEY,
  hash TEXT UNIQUE,
  created TEXT,
  modified TEXT,
  status TEXT,
  name TEXT,
  percent_progress NUMERIC,
  ratio NUMERIC,
  label TEXT,
  msg TEXT,
  folder TEXT,
  tp_state TEXT DEFAULT NULL
);
EOQ
        db.execute( schema )

        # Copy torrent data from tmp table to updated torrents table
        rows = db.execute("SELECT * FROM 'new_torrents';")
        rows.each do |row|
          q = <<EOQ
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
values ("#{row[0]}", "#{row[1]}", "#{row[2]}", #{row[3]}, #{row[4]}, "#{row[5]}", "#{row[6]}", "#{row[7]}");
EOQ

          result = db.execute q
        end

        # Cleanup the tmp table
        result = db.execute("DROP TABLE 'new_torrents';")

        db.execute('PRAGMA user_version = 2;')
        db.log "v2 migration complete." if db.verbose
      end
    end # class
  end # class Database



end # module TorrentProcessor
