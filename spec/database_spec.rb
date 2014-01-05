require 'spec_helper'
include TorrentProcessor

def delete_db(path)
  trys = 0
  while File.exists?(path)
    if trys > 1000
      puts "You must be on WinBLOWS!"
      puts "Unable to delete #{path} after 1000 trys"
      return
    end
    begin
      #puts "trys: #{trys}"
      FileUtils.rm path
    rescue Errno::EACCES => e
      trys += 1
    end
  end
end

def tdata hash, name
  data = %w(hash 1 name 100 100 100 100 1000 10 20 1h TV 5 10 1 Y 1 0 unk1 unk2 message unk4 unk5 unk6 unk7 folder unk8)
  data[0] = hash
  data[2] = name
  TorrentProcessor::TorrentData.new data
end

describe Database do

  let(:db) { obj = Database.new(controller); obj.filename = db_file; obj }
  let(:controller) { double("controller", :cfg => {:appPath => app_data_path}) }
  let(:app_data_path) { FileUtils.mkdir_p('tmp/spec/database'); 'tmp/spec/database' }
  let(:db_path) { File.join(app_data_path, db_file) }
  let(:db_file) { 'test.db' }

  it "database file name can be overridden" do
    db.filename = 'testing.db'
    expect(db.filename).to eq 'testing.db'
  end

  it "defaults to 'tp.db'" do
    test_db = Database.new(controller)
    expect(test_db.filename).to eq 'tp.db'
  end

  it "creates a new database at cfg[:appPath]" do
    db.connect
    expect(File.exists?(db_path))
  end

  context "#database" do

    it "connects to a database if not already connected" do
      database = db.database
      expect(database).to_not be nil
      expect(database.closed?).to be false
    end
  end

  context "#close" do

    it "closes a database" do
      database = db.database
      db.close
      expect(database.closed?).to be true
    end

    it "has no effect if database already closed" do
      database = db.database
      db.close
      expect(database.closed?).to be true
      db.close
    end
  end

  context "#connect" do

    it "connects to a database and returns the instance" do
      database = db.connect
      expect(database).to_not be nil
      expect(database.public_methods.include?(:execute))
      expect(database.public_methods.include?(:execute_batch))
    end
  end

  context "#create_database" do

    before(:each) do
      db.close
      delete_db db_path
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

  context "#schema_version" do

    before(:each) do
      db.close
      delete_db db_path
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
      delete_db db_path
    end

    context ".upgrade_1" do

      before(:each) do
        db.connect
        db.create_database
        5.times do |i|
          db.create(tdata("ab#{i}", "Name #{i}"))
        end
      end

      it "upgrades the schema to version 1" do
        Database::Schema.upgrade_1 db
        expect(db.schema_version).to eq 1
      end

      it "drops app_lock table" do
        expect(db.execute('SELECT * FROM app_lock;').size).to eq 1

        Database::Schema.upgrade_1 db
        expect { db.execute('SELECT * FROM app_lock;') }.to raise_exception
      end

      it "changes tp_state value 'download complete' to 'downloaded'" do

        db.update_torrent_state('ab0', 'download complete')
        db.update_torrent_state('ab2', 'download complete')
        expect(db.execute('SELECT * FROM torrents;').size).to eq 5

        Database::Schema.upgrade_1 db
        expect(db.execute('SELECT * FROM torrents WHERE tp_state ="download complete";').size).to eq 0
      end
    end
  end
end
