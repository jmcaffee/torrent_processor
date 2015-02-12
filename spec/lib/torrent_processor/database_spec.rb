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
    obj.filepath = 'memory'
    obj
  end

  let(:init_args) do
    {
      :cfg => mock_cfg('database'),
      #:verbose => true, # Default: false
      :logger => ::ScreenLogger,
    }
  end

  let(:db_path)       { File.join(tmp_path, db_file) }
  let(:db_file)       { 'test.db' }

  it "database file name can be overridden" do
    DatabaseHelper.with_mem_db do |db|
      db.filename = 'testing.db'
      expect(db.filename).to eq 'testing.db'
    end
  end

  it "database file path can be overridden" do
    DatabaseHelper.with_mem_db do |db|
      db.filepath = 'memory'
      expect(db.filepath).to eq 'memory'
    end
  end

  it "defaults to 'tp.db'" do
    test_db = Database.new(init_args)
    expect(test_db.filename).to eq 'tp.db'
  end

  it "creates a new database at cfg[:app_path]" do
    test_db = Database.new(init_args)
    test_db.connect
    test_db.create_database
    expect(File.exists?(test_db.filepath)).to be true
  end

  context "#database" do

    it "connects to a database if not already connected" do
      DatabaseHelper.with_mem_db do |db|
        database = db.database
        expect(database).to_not be nil
        expect(db.closed?).to be false
      end
    end
  end

  context "#close" do

    it "closes a database" do
      DatabaseHelper.with_mem_db do |db|
        database = db.database
        db.close
        expect(db.closed?).to be true
      end
    end

    it "has no effect if database already closed" do
      DatabaseHelper.with_mem_db do |db|
        database = db.database
        db.close
        expect(db.closed?).to be true
        db.close
      end
    end
  end

  context "#connect" do

    it "connects to a database and returns the instance" do
      DatabaseHelper.with_mem_db do |db|
        database = db.database
        expect(database).to_not be nil
      end
    end
  end

  context "#create_database" do

    it "creates the database schema" do
      #DatabaseHelper.with_mem_db({:verbose => true}) do |db|
      DatabaseHelper.with_mem_db do |db|
        db.create_database
        result = db.execute('SELECT * FROM torrents;')
        expect(result.size).to eq 0
      end
    end

    it "gracefully handles already existing tables/triggers" do
      DatabaseHelper.with_mem_db do |db|
        db.create_database
        db.create_database
      end
    end
  end

  context "#find_torrent_by_id" do

    it "returns a hash of torrent data" do
      DatabaseHelper.with_mem_db do |db|
        db.create_database
        5.times do |i|
          db.create(tdata("ab#{i+1}", "Name #{i+1}"))
        end

        actual = db.find_torrent_by_id(1)
        expect(actual[:name]).to eq 'Name 1'
      end
    end
  end

  context "#schema_version" do

    it "returns the current schema version" do
      DatabaseHelper.with_mem_db do |db|
        db.create_database

        db.execute('PRAGMA user_version = 3;')
        expect(db.schema_version).to eq 3
      end
    end
  end

  context "#exists_in_db?" do

    it "returns true if hash in db" do
      DatabaseHelper.with_mem_db do |db|
        db.create_database
        torrents = {}
        5.times do |i|
          t = tdata("ab#{i+1}", "Name #{i+1}")
          torrents[t.hash] = t
        end

        torrents.each do |k,v|
          db.create v
        end

        expect(db.exists_in_db?("ab1")).to eq true
      end
    end

    it "returns false if hash not in db" do
      DatabaseHelper.with_mem_db do |db|
        db.create_database
        torrents = {}
        5.times do |i|
          t = tdata("ab#{i+1}", "Name #{i+1}")
          torrents[t.hash] = t
        end

        torrents.each do |k,v|
          db.create v
        end

        expect(db.exists_in_db?("xyz")).to eq false
      end
    end
  end

  context "#execute_batch" do

    it "executes insert query in transaction mode" do
      DatabaseHelper.with_mem_db do |db|
        db.create_database
        torrents = {}
        5.times do |i|
          t = tdata("ab#{i+1}", "Name #{i+1}")
          torrents[t.hash] = t
        end

        # Record shouldn't exist yet.
        expect(db.exists_in_db?("ab3")).to eq false

        query = db.build_batch_insert_query torrents
        db.execute_batch query

        expect(db.exists_in_db?("ab3")).to eq true
      end
    end

    it "executes update query in transaction mode" do
      DatabaseHelper.with_mem_db do |db|
        db.create_database
        # Populate the database
        torrents = {}
        5.times do |i|
          t = tdata("ab#{i+1}", "Name #{i+1}")
          torrents[t.hash] = t
        end

        query = db.build_batch_insert_query torrents
        db.execute_batch query

        # Update the database with name changes
        torrents = {}
        5.times do |i|
          t = tdata("ab#{i+1}", "Name #{i+5}")
          torrents[t.hash] = t
        end

        query = db.build_batch_update_query torrents
        db.execute_batch query

        result = db.read('SELECT name FROM torrents WHERE hash = "ab4"')
        expect( result.first.first ).to eq 'Name 8'
      end
    end
  end

  context "#update_torrents" do

    it "inserts and updates torrents" do
      DatabaseHelper.with_mem_db do |db|
        db.create_database
        # Populate the database so these will be updates.
        torrents = {}
        5.times do |i|
          t = tdata("ab#{i+1}", "Name #{i+1}")
          torrents[t.hash] = t
        end

        query = db.build_batch_insert_query torrents
        db.execute_batch query

        # Add new records to be inserts
        5.times do |i|
          t = tdata("ab#{i+6}", "Name #{i+6}")
          torrents[t.hash] = t
        end

        db.update_torrents torrents

        result = db.read('SELECT name FROM torrents WHERE hash = "ab2"')
        expect( result.first.first ).to eq 'Name 2'

        result = db.read('SELECT name FROM torrents WHERE hash = "ab8"')
        expect( result.first.first ).to eq 'Name 8'
      end
    end
  end

  context Database::Schema do

    context ".perform_migrations" do

      it "runs migrations when DB schema version is less than schema VERSION" do
        DatabaseHelper.with_mem_db do |db|
          db.create_database

          Database::Schema.perform_migrations db
          expect(db.schema_version).to eq 1
        end
      end

      it "doesn't run migrations when DB schema version >= schema VERSION" do
        DatabaseHelper.with_mem_db do |db|
          db.create_database

          db.execute('PRAGMA user_version = 1;')
          Database::Schema.perform_migrations db
          expect(db.execute('SELECT * FROM app_lock;').size).to eq 1
        end
      end
    end

    context ".migrate_to_v1" do

      it "upgrades the schema to version 1" do
        DatabaseHelper.with_mem_db do |db|
          db.execute('PRAGMA user_version = 0;')
          db.create_database
          5.times do |i|
            db.create(tdata("ab#{i}", "Name #{i}"))
          end

          Database::Schema.migrate_to_v1 db
          expect(db.schema_version).to eq 1
        end
      end

      it "does not run if schema version > 1" do
        DatabaseHelper.with_mem_db do |db|
          db.execute('PRAGMA user_version = 0;')
          db.create_database
          5.times do |i|
            db.create(tdata("ab#{i}", "Name #{i}"))
          end

          db.execute('PRAGMA user_version = 3;')
          Database::Schema.migrate_to_v1 db

          expect(db.execute('SELECT * FROM app_lock;').size).to eq 1
          expect(db.schema_version).to eq 3
        end
      end

      it "drops app_lock table" do
        DatabaseHelper.with_mem_db do |db|
          db.execute('PRAGMA user_version = 0;')
          db.create_database
          5.times do |i|
            db.create(tdata("ab#{i}", "Name #{i}"))
          end

          expect(db.execute('SELECT * FROM app_lock;').size).to eq 1

          Database::Schema.migrate_to_v1 db
          expect { db.execute('SELECT * FROM app_lock;') }.to raise_exception
        end
      end

      it "changes tp_state value 'download complete' to 'downloaded'" do
        DatabaseHelper.with_mem_db do |db|
          db.execute('PRAGMA user_version = 0;')
          db.create_database
          5.times do |i|
            db.create(tdata("ab#{i}", "Name #{i}"))
          end

          old_state = 'download complete'
          db.update_torrent_state('ab0', old_state)
          db.update_torrent_state('ab2', old_state)

          expect(db.execute('SELECT * FROM torrents;').size).to eq 5

          Database::Schema.migrate_to_v1 db
          select_old_state_from_torrents = 'SELECT * FROM torrents WHERE tp_state ="' + old_state + '";'
          expect(
            db.execute( select_old_state_from_torrents ).size).to eq 0
        end
      end

      it "changes tp_state value 'awaiting processing' to 'processing'" do
        DatabaseHelper.with_mem_db do |db|
          db.execute('PRAGMA user_version = 0;')
          db.create_database
          5.times do |i|
            db.create(tdata("ab#{i}", "Name #{i}"))
          end

          old_state = 'awaiting processing'
          db.update_torrent_state('ab0', old_state)
          db.update_torrent_state('ab2', old_state)

          expect(db.execute('SELECT * FROM torrents;').size).to eq 5

          Database::Schema.migrate_to_v1 db
          select_old_state_from_torrents = 'SELECT * FROM torrents WHERE tp_state ="' + old_state + '";'
          expect(
            db.execute( select_old_state_from_torrents ).size).to eq 0
        end
      end

      it "changes tp_state value 'awaiting removal' to 'removing'" do
        DatabaseHelper.with_mem_db do |db|
          db.execute('PRAGMA user_version = 0;')
          db.create_database
          5.times do |i|
            db.create(tdata("ab#{i}", "Name #{i}"))
          end

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
end
