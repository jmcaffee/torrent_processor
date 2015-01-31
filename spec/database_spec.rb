require 'spec_helper'
include TorrentProcessor

def tdata hash, name
  data = %w(hash 1 name 100 100 100 100 1000 10 20 1h TV 5 10 1 Y 1 0 unk1 unk2 message unk4 unk5 unk6 unk7 folder unk8)
  data[0] = hash
  data[2] = name
  TorrentProcessor::Service::UTorrent::TorrentData.new data
end

describe Database do

  let(:tmp_path) do
    pth = 'tmp/spec/database'
    mkpath pth
    pth
  end

  let(:db) do
    obj = Database.new(init_args)
    obj.filename = db_file
    obj
  end

  let(:init_args) do
    {
      :cfg => cfg_stub,
      #:verbose => true, # Default: false
      :logger => ::ScreenLogger,
    }
  end

  let(:cfg_stub) do
    cfg = TorrentProcessor.configuration

    cfg.app_path          = tmp_path
    cfg.logging           = false
    cfg.max_log_size      = 0
    cfg.log_dir           = tmp_path
    cfg.tv_processing     = File.join(tmp_path, 'media/tv')
    cfg.movie_processing  = File.join(tmp_path, 'media/movies')
    cfg.other_processing  = File.join(tmp_path, 'media/other')
    cfg.filters           = {}

    cfg.utorrent.ip                     = '192.168.1.103'
    cfg.utorrent.port                   = '8082'
    cfg.utorrent.user                   = 'admin'
    cfg.utorrent.pass                   = 'abc'
    cfg.utorrent.dir_completed_download = File.join(tmp_path, 'torrents/completed')
    cfg.utorrent.seed_ratio             = 0

    cfg.tmdb.api_key              = '***REMOVED***'
    cfg.tmdb.language             = 'en'
    cfg.tmdb.target_movies_path   = File.join(tmp_path, 'movies_final')
    cfg.tmdb.can_copy_start_time  = "00:00"
    cfg.tmdb.can_copy_stop_time   = "23:59"
    cfg
  end

  let(:db_path)       { File.join(tmp_path, db_file) }
  let(:db_file)       { 'test.db' }

  it "database file name can be overridden" do
    db.filename = 'testing.db'
    expect(db.filename).to eq 'testing.db'
  end

  it "defaults to 'tp.db'" do
    test_db = Database.new(init_args)
    expect(test_db.filename).to eq 'tp.db'
  end

  it "creates a new database at cfg[:appPath]" do
    db.connect
    expect(File.exists?(db_path)).to be true
  end

  context "#database" do

    it "connects to a database if not already connected" do
      database = db.database
      expect(database).to_not be nil
      expect(db.closed?).to be false
    end
  end

  context "#close" do

    it "closes a database" do
      database = db.database
      db.close
      expect(db.closed?).to be true
    end

    it "has no effect if database already closed" do
      database = db.database
      db.close
      expect(db.closed?).to be true
      db.close
    end
  end

  context "#connect" do

    it "connects to a database and returns the instance" do
      database = db.connect
      expect(database).to_not be nil
    end
  end

  context "#create_database" do

    before(:each) do
      db.close
      blocking_file_delete db_path
    end

    it "creates the database schema" do
      db.connect
      db.create_database
      result = db.execute('SELECT * FROM torrents;')
      expect(result.size).to be 0
    end

    it "gracefully handles already existing tables/triggers" do
      db.connect
      db.create_database
      db.create_database
    end
  end

  context "#find_torrent_by_id" do

      before(:each) do
        db.close
        blocking_file_delete db_path
        db.connect
        db.create_database
        5.times do |i|
          db.create(tdata("ab#{i+1}", "Name #{i+1}"))
        end
      end

    it "returns a hash of torrent data" do
      actual = db.find_torrent_by_id(1)
      expect(actual[:name]).to eq 'Name 1'
    end
  end

  context "#schema_version" do

    before(:each) do
      db.close
      blocking_file_delete db_path
    end

    it "returns the current schema version" do
      db.connect
      db.execute('PRAGMA user_version = 3;')
      expect(db.schema_version).to eq 3
    end
  end

  context Database::Schema do

    before(:each) do
      db.close
      blocking_file_delete db_path
    end

    context ".perform_migrations" do

      before(:each) do
        db.connect
        db.create_database
      end

      it "runs migrations when DB schema version is less than schema VERSION" do
        Database::Schema.perform_migrations db
        expect(db.schema_version).to eq 1
      end

      it "doesn't run migrations when DB schema version >= schema VERSION" do
        db.execute('PRAGMA user_version = 1;')
        Database::Schema.perform_migrations db
        expect(db.execute('SELECT * FROM app_lock;').size).to eq 1
      end
    end

    context ".migrate_to_v1" do

      before(:each) do
        db.connect
        db.create_database
        5.times do |i|
          db.create(tdata("ab#{i}", "Name #{i}"))
        end
      end

      it "upgrades the schema to version 1" do
        Database::Schema.migrate_to_v1 db
        expect(db.schema_version).to eq 1
      end

      it "does not run if schema version > 1" do
        db.execute('PRAGMA user_version = 3;')
        Database::Schema.migrate_to_v1 db

        expect(db.execute('SELECT * FROM app_lock;').size).to eq 1
        expect(db.schema_version).to eq 3
      end

      it "drops app_lock table" do
        expect(db.execute('SELECT * FROM app_lock;').size).to eq 1

        Database::Schema.migrate_to_v1 db
        expect { db.execute('SELECT * FROM app_lock;') }.to raise_exception
      end

      it "changes tp_state value 'download complete' to 'downloaded'" do

        old_state = 'download complete'
        db.update_torrent_state('ab0', old_state)
        db.update_torrent_state('ab2', old_state)

        expect(db.execute('SELECT * FROM torrents;').size).to eq 5

        Database::Schema.migrate_to_v1 db
        select_old_state_from_torrents = 'SELECT * FROM torrents WHERE tp_state ="' + old_state + '";'
        expect(
          db.execute( select_old_state_from_torrents ).size).to eq 0
      end

      it "changes tp_state value 'awaiting processing' to 'processing'" do

        old_state = 'awaiting processing'
        db.update_torrent_state('ab0', old_state)
        db.update_torrent_state('ab2', old_state)

        expect(db.execute('SELECT * FROM torrents;').size).to eq 5

        Database::Schema.migrate_to_v1 db
        select_old_state_from_torrents = 'SELECT * FROM torrents WHERE tp_state ="' + old_state + '";'
        expect(
          db.execute( select_old_state_from_torrents ).size).to eq 0
      end

      it "changes tp_state value 'awaiting removal' to 'removing'" do

        old_state = 'awaiting removal'
        db.update_torrent_state('ab0', old_state)
        db.update_torrent_state('ab2', old_state)

        expect(db.execute('SELECT * FROM torrents;').size).to eq 5

        Database::Schema.migrate_to_v1 db
        select_old_state_from_torrents = 'SELECT * FROM torrents WHERE tp_state ="' + old_state + '";'
        expect(
          db.execute( select_old_state_from_torrents ).size).to eq 0
      end
    end
  end
end
