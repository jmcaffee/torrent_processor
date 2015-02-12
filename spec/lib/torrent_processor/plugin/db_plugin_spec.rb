require 'spec_helper'

include TorrentProcessor::Plugin

describe DBPlugin do

  subject(:plugin) { DBPlugin.new }

  let(:args) do
    {
      :cmd      => cmd,
      :logger   => CaptureLogger,
      :database => Mocks.db,
      :utorrent => Mocks.utorrent,
    }
  end

  before(:each) do
    CaptureLogger.reset
  end

  describe '#db_connect' do

    let(:cmd) { '.dbconnect' }

    it 'connects to the database' do
      expect(plugin.db_connect(args)).to be_truthy
      expect( CaptureLogger.contains 'DB connection established' )
    end
  end # #db_connect

  describe '#db_close' do

    let(:cmd) { '.dbclose' }

    it 'closes the database connection' do
      expect(plugin.db_close(args)).to be_truthy
      expect( CaptureLogger.contains 'DB closed' )
    end
  end # #db_close

  describe '#db_update' do

    let(:cmd) { '.update' }

    it 'clear all torrent data from DB and refresh from uTorrent' do
      expect(plugin.db_update(args)).to be_truthy
      expect( CaptureLogger.contains 'DB updated' )
    end
  end # #db_update

  describe '#db_changestate' do

    context 'no FROM or TO state' do

      let(:cmd) { '.changestate' }

      it 'displays usage information' do
        expect(plugin.db_changestate(args)).to be_truthy
        expect( CaptureLogger.contains 'usage: .changestate FROM TO [ID]' )
      end
    end # no FROM or TO state

    context 'FROM: NULL, TO: removing' do

      context 'no rows found' do
        let(:cmd) { '.changestate NULL removing 1' }

        it 'makes no changes' do
          expect(plugin.db_changestate(args)).to be_truthy
          expect( CaptureLogger.contains "Found 0 rows matching 'NULL' AND id = 1." )
          expect( CaptureLogger.does_not_contain('Done.') )
        end
      end # no rows found

      context '1 row found' do
        let(:cmd) { '.changestate NULL removing 2' }

        it 'transition a torrents state to the next' do
          expect(plugin.db_changestate(args)).to be_truthy
          expect( CaptureLogger.contains "Found 1 rows matching 'NULL' AND id = 2." )
          expect( CaptureLogger.contains 'Done.' )
        end
      end # no rows found
    end # FROM: NULL, TO: removing, ID: 1
  end # #db_changestate

  describe '#db_torrent_ratios' do

    let(:cmd) { '.ratios' }

    it 'display a table of torrents and their current seeding ratios' do
      expect(plugin.db_torrent_ratios(args)).to be_truthy
      expect( CaptureLogger.contains 'ID | Ratio | Name' )
      expect( CaptureLogger.contains '2 | 1500 | TestTorrent1' )
    end
  end # #db_torrent_ratios

  describe '#db_reconcile' do

    let(:cmd) { '.reconcile' }

    it 'not implemented' do
      expect(plugin.db_reconcile(args)).to be_truthy
      expect( CaptureLogger.contains 'Not implemented' )
    end
  end # #db_reconcile

  describe '#db_schema' do

    let(:cmd) { '.schema' }

    it 'displays database schema' do
      expect(plugin.db_schema(args)).to be_truthy
      expect( CaptureLogger.contains 'Table description(s)' )
    end
  end # #db_schema

  describe '#db_torrent_states' do

    let(:cmd) { '.states' }

    it 'displays current state of each torrent' do
      expect(plugin.db_torrent_states(args)).to be_truthy
      expect( CaptureLogger.contains 'ID | TP State | Name' )
      expect( CaptureLogger.contains '2 | removing | TestTorrent1' )
    end
  end # #db_torrent_states

  describe '#db_list_tables' do

    let(:cmd) { '.tables' }

    it 'displays list of all tables in DB' do
      expect(plugin.db_list_tables(args)).to be_truthy
      expect( CaptureLogger.contains 'Tables in DB' )
      expect( CaptureLogger.contains 'torrents' )
    end
  end # #db_list_tables

  describe '#db_upgrade_db' do

    let(:cmd) { '.upgrade' }

    it 'displays list of all tables in DB' do
      expect(plugin.db_upgrade_db(args)).to be_truthy
      expect( CaptureLogger.contains 'Run all DB migrations' )
    end
  end # #db_upgrade_db
end
