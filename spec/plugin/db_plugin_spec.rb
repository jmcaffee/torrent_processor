require 'spec_helper'
require 'torrent_spec_helper'

include TorrentProcessor::Plugin

describe DBPlugin do

  subject(:plugin) { DBPlugin.new }

  let(:args) do
    {
      :cmd      => cmd,
      :logger   => CaptureLogger,
      :database => database_stub,
      :utorrent => utorrent_stub,
    }
  end

  let(:database_stub) do
    obj = double('database')
    obj.stub(:connect)  { true }
    obj.stub(:close)    { true }
    obj.stub(:execute) do |q|
      if q.include? 'SELECT hash FROM torrents'
        [
          [ 'abc' ]
        ]
      elsif q.include? 'SELECT hash, name FROM torrents WHERE (tp_state IS NULL AND id = 2)'
        [
          [ 'abc' ]
        ]
      elsif q.include? 'SELECT id,ratio,name from torrents'
        [
          [ 2, 1500, 'TestTorrent1' ]
        ]
      elsif q.include? 'SELECT id,tp_state,name from torrents'
        [
          [ 2, 'removing', 'TestTorrent1' ]
        ]
      elsif q.include? "SELECT name from sqlite_master WHERE type = 'table' ORDER BY name"
        [
          [ 'torrents' ]
        ]
      else
        []
      end
    end

    obj.stub(:delete_torrent) do |arg|
    end

    obj.stub(:read_cache) { 'cache' }
    obj.stub(:update_cache)
    obj.stub(:update_torrents)
    obj.stub(:upgrade)

    obj
  end

  let(:utorrent_stub) do
    obj = double('utorrent')
    obj.stub(:cache)                      { 'cache' }
    obj.stub(:get_torrent_list)           { TorrentSpecHelper.utorrent_torrent_list_data() }
    obj.stub(:torrents)                   { TorrentSpecHelper.utorrent_torrents_data() }

    obj
  end

  before(:each) do
    CaptureLogger.reset
  end

  describe '#db_connect' do

    let(:cmd) { '.dbconnect' }

    it 'connects to the database' do
      expect(plugin.db_connect(args)).to be_true
      expect( CaptureLogger.contains 'DB connection established' )
    end
  end # #db_connect

  describe '#db_close' do

    let(:cmd) { '.dbclose' }

    it 'closes the database connection' do
      expect(plugin.db_close(args)).to be_true
      expect( CaptureLogger.contains 'DB closed' )
    end
  end # #db_close

  describe '#db_update' do

    let(:cmd) { '.update' }

    it 'clear all torrent data from DB and refresh from uTorrent' do
      expect(plugin.db_update(args)).to be_true
      expect( CaptureLogger.contains 'DB updated' )
    end
  end # #db_update

  describe '#db_changestate' do

    context 'no FROM or TO state' do

      let(:cmd) { '.changestate' }

      it 'displays usage information' do
        expect(plugin.db_changestate(args)).to be_true
        expect( CaptureLogger.contains 'usage: .changestate FROM TO [ID]' )
      end
    end # no FROM or TO state

    context 'FROM: NULL, TO: removing' do

      context 'no rows found' do
        let(:cmd) { '.changestate NULL removing 1' }

        it 'makes no changes' do
          expect(plugin.db_changestate(args)).to be_true
          expect( CaptureLogger.contains "Found 0 rows matching 'NULL' AND id = 1." )
          expect( CaptureLogger.does_not_contain('Done.') )
        end
      end # no rows found

      context '1 row found' do
        let(:cmd) { '.changestate NULL removing 2' }

        it 'transition a torrents state to the next' do
          expect(plugin.db_changestate(args)).to be_true
          expect( CaptureLogger.contains "Found 1 rows matching 'NULL' AND id = 2." )
          expect( CaptureLogger.contains 'Done.' )
        end
      end # no rows found
    end # FROM: NULL, TO: removing, ID: 1
  end # #db_changestate

  describe '#db_torrent_ratios' do

    let(:cmd) { '.ratios' }

    it 'display a table of torrents and their current seeding ratios' do
      expect(plugin.db_torrent_ratios(args)).to be_true
      expect( CaptureLogger.contains 'ID | Ratio | Name' )
      expect( CaptureLogger.contains '2 | 1500 | TestTorrent1' )
    end
  end # #db_torrent_ratios

  describe '#db_reconcile' do

    let(:cmd) { '.reconcile' }

    it 'not implemented' do
      expect(plugin.db_reconcile(args)).to be_true
      expect( CaptureLogger.contains 'Not implemented' )
    end
  end # #db_reconcile

  describe '#db_schema' do

    let(:cmd) { '.schema' }

    it 'displays database schema' do
      expect(plugin.db_schema(args)).to be_true
      expect( CaptureLogger.contains 'Table description(s)' )
    end
  end # #db_schema

  describe '#db_torrent_states' do

    let(:cmd) { '.states' }

    it 'displays current state of each torrent' do
      expect(plugin.db_torrent_states(args)).to be_true
      expect( CaptureLogger.contains 'ID | TP State | Name' )
      expect( CaptureLogger.contains '2 | removing | TestTorrent1' )
    end
  end # #db_torrent_states

  describe '#db_list_tables' do

    let(:cmd) { '.tables' }

    it 'displays list of all tables in DB' do
      expect(plugin.db_list_tables(args)).to be_true
      expect( CaptureLogger.contains 'Tables in DB' )
      expect( CaptureLogger.contains 'torrents' )
    end
  end # #db_list_tables

  describe '#db_upgrade_db' do

    let(:cmd) { '.upgrade' }

    it 'displays list of all tables in DB' do
      expect(plugin.db_upgrade_db(args)).to be_true
      expect( CaptureLogger.contains 'Run all DB migrations' )
    end
  end # #db_upgrade_db
end
