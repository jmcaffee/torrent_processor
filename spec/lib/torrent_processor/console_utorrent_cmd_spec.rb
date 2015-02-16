require 'spec_helper'

include TorrentProcessor

describe Console do

  subject(:console) { Console.new(init_args) }

  let(:init_args) do
    {
      :logger     => CaptureLogger,
      :webui      => Mocks.utorrent,
      :webui_type => :utorrent,
      :database   => Mocks.db,
    }
  end

  describe '#process_cmd' do

    before(:each) { CaptureLogger.reset }

    context 'cmd: .testcon' do

      it 'tests torrent app connection' do
        expect(console.process_cmd('.testcon')).to be_truthy
        expect(CaptureLogger.contains('Connected successfully')).to be_truthy
      end
    end # cmd: .testcon

    context 'cmd: .tsettings' do

      it 'displays torrent app settings' do
        expect(console.process_cmd('.tsettings')).to be_truthy
        expect(CaptureLogger.contains('["webui.uconnect_toolbar_ever", 1, "true", {"access"=>"R"}]'))
      end
    end # cmd: .utsettings

    context 'cmd: .jobprops' do

      it 'display torrent app job properties' do
        allow_any_instance_of(TorrentProcessor::Plugin::UTPlugin).to receive(:getInput).and_return('0')
        expect(console.process_cmd('.jobprops')).to be_truthy
        expect { CaptureLogger.contains 'Horizon.S52E16' }
      end
    end # cmd: .jobprops

    context 'cmd: .tlist' do

      it 'display list of torrents torrent app is monitoring' do
        expect(console.process_cmd('.tlist')).to be_truthy
        expect { CaptureLogger.contains 'Horizon.S52E16' }
      end
    end # cmd: .tlist

    context 'cmd: .tnames' do

      it 'display list of torrent names torrent app is monitoring' do
        expect(console.process_cmd('.tnames')).to be_truthy
        expect { CaptureLogger.contains 'Horizon.S52E16' }
      end
    end # cmd: .tnames

    context 'cmd: .tdetails' do

      it 'display details of a torrent in torrent app' do
        allow_any_instance_of(TorrentProcessor::Plugin::UTPlugin).to receive(:getInput).and_return('0')
        expect(console.process_cmd('.tdetails')).to be_truthy
        expect { CaptureLogger.contains 'availability       : 65536' }
      end
    end # cmd: .tdetails

    context 'cmd: .listquery' do

      it 'run a list query against torrent app data' do
        expect(console.process_cmd('.listquery')).to be_truthy
        expect { CaptureLogger.contains '520023045, 0, 0, 0, 0, 0, "TV",' }
      end
    end # cmd: .listquery
  end # #process_cmd
end


