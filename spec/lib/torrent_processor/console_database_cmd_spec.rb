require 'spec_helper'

include TorrentProcessor

describe Console do

  include DatabaseHelper
  include UTorrentHelper

  subject(:console) { Console.new(init_args) }

  let(:init_args) do
    {
      :logger => CaptureLogger,
      :utorrent => utorrent_stub(),
      :database => database_stub(),
    }
  end

  describe '#process_cmd' do

    before(:each) { CaptureLogger.reset }

    context 'cmd: .dbconnect' do

      it 'connects to the DB' do
        expect(console.process_cmd('.dbconnect')).to be_truthy
      end
    end # cmd: .dbconnect

    context 'cmd: .dbclose' do

      it 'closes the DB connection' do
        expect(console.process_cmd('.dbclose')).to be_truthy
      end
    end # cmd: .dbclose

    context 'cmd: .update' do

      it 'clear out DB and update with fresh torrent data' do
        expect(console.process_cmd('.update')).to be_truthy
      end
    end # cmd: .update

    context 'cmd: .changestate' do

      it 'change torrent states within the DB' do
        expect(console.process_cmd('.changestate')).to be_truthy
      end
    end # cmd: .changestate

    context 'cmd: .ratios' do

      it 'display the current torrent ratios within the DB' do
        expect(console.process_cmd('.ratios')).to be_truthy
      end
    end # cmd: .ratios

    context 'cmd: .reconcile' do

      it 'reconcile the DB with uTorrent current state (TODO)' do
        expect(console.process_cmd('.reconcile')).to be_truthy
      end
    end # cmd: .reconcile

    context 'cmd: .schema' do

      it 'display the DB schema' do
        expect(console.process_cmd('.schema')).to be_truthy
      end
    end # cmd: .schema

    context 'cmd: .states' do

      it 'display current torrent states within the DB' do
        expect(console.process_cmd('.states')).to be_truthy
      end
    end # cmd: .states

    context 'cmd: .tables' do

      it 'displays tables used in database' do
        expect(console.process_cmd('.tables')).to be_truthy
      end
    end # cmd: .tables

    context 'cmd: .upgrade' do

      it 'run DB upgrade migrations' do
        expect(console.process_cmd('.upgrade')).to be_truthy
      end
    end # cmd: .upgrade
  end # #process_cmd
end
