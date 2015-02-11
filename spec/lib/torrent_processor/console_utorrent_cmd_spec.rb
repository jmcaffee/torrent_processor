require 'spec_helper'

include TorrentProcessor

describe Console do

  subject(:console) { Console.new(init_args) }

  let(:init_args) do
    {
      :logger => CaptureLogger,
      :utorrent => utorrent_stub,
      :database => database_stub,
    }
  end

  let(:utorrent_stub) do
    obj = double('utorrent')
    obj.stub(:get_utorrent_settings)
    obj.stub(:send_get_query)
    obj.stub(:settings)                   { TorrentSpecHelper.utorrent_settings_data() }
    obj.stub(:get_torrent_job_properties) { TorrentSpecHelper.utorrent_job_properties_data() }
    obj.stub(:get_torrent_list)           { TorrentSpecHelper.utorrent_torrent_list_data() }
    obj.stub(:torrents)                   { TorrentSpecHelper.utorrent_torrents_data() }
    obj
  end

  let(:database_stub) do
    obj = double('database')
  end

  describe '#process_cmd' do

    before(:each) { CaptureLogger.reset }

    context 'cmd: .testcon' do

      it 'tests utorrent connection' do
        expect(console.process_cmd('.testcon')).to be_truthy
        expect(CaptureLogger.contains('Connected successfully')).to be_truthy
      end
    end # cmd: .testcon

    context 'cmd: .utsettings' do

      it 'displays utorrent settings' do
        expect(console.process_cmd('.utsettings')).to be_truthy
        expect(CaptureLogger.contains('["webui.uconnect_toolbar_ever", 1, "true", {"access"=>"R"}]'))
      end
    end # cmd: .utsettings

    context 'cmd: .jobprops' do

      it 'display utorrent job properties' do
        TorrentProcessor::Plugin::UTPlugin.any_instance.stub(:getInput).and_return('0')
        expect(console.process_cmd('.jobprops')).to be_truthy
        expect { CaptureLogger.contains 'Horizon.S52E16' }
      end
    end # cmd: .jobprops

    context 'cmd: .tlist' do

      it 'display list of torrents utorrent is monitoring' do
        expect(console.process_cmd('.tlist')).to be_truthy
        expect { CaptureLogger.contains 'Horizon.S52E16' }
      end
    end # cmd: .tlist

    context 'cmd: .tnames' do

      it 'display list of torrent names utorrent is monitoring' do
        expect(console.process_cmd('.tnames')).to be_truthy
        expect { CaptureLogger.contains 'Horizon.S52E16' }
      end
    end # cmd: .tnames

    context 'cmd: .tdetails' do

      it 'display details of a torrent in utorrent' do
        TorrentProcessor::Plugin::UTPlugin.any_instance.stub(:getInput).and_return('0')
        expect(console.process_cmd('.tdetails')).to be_truthy
        expect { CaptureLogger.contains 'availability       : 65536' }
      end
    end # cmd: .tdetails

    context 'cmd: .listquery' do

      it 'run a list query against utorrent data' do
        expect(console.process_cmd('.listquery')).to be_truthy
        expect { CaptureLogger.contains '520023045, 0, 0, 0, 0, 0, "TV",' }
      end
    end # cmd: .listquery
  end # #process_cmd
end


