##############################################################################
# File::    ut_plugin_spec.rb
# Purpose:: uTorrent Plugin specification
#
# Author::    Jeff McAffee 2014-01-14
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'spec_helper'
require 'torrent_spec_helper'

include TorrentProcessor::Plugin

describe UTPlugin do

  before(:each) { CaptureLogger.reset }

  subject(:plugin) { UTPlugin.new }

  let(:args) do
    {
      :cmd      => cmd,
      :logger   => CaptureLogger,
      :utorrent => utorrent_stub,
      :database => database_stub,
    }
  end

  let(:database_stub) do
    obj = double('database')
    obj.stub(:close) { true }
    obj
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

  context '#ut_test_connection' do

    let(:cmd) { '.testcon' }

    it "tests the uTorrent connection" do
      plugin.ut_test_connection args
    end
  end

  context '#ut_settings' do

    let(:cmd) { '.utsettings' }

    it "returns current uTorrent settings" do
      plugin.ut_settings args
    end
  end

  context '#ut_jobprops' do

    let(:cmd) { '.jobprops' }

    it "returns current uTorrent job properties" do
      TorrentProcessor::Plugin::UTPlugin.any_instance.stub(:getInput).and_return('0')
      plugin.ut_jobprops args
      expect { CaptureLogger.contains 'Horizon.S52E16' }
    end
  end

  context '#ut_list' do

    let(:cmd) { '.tlist' }

    it "returns a list of torrents uTorrent is monitoring" do
      plugin.ut_list args
      expect { CaptureLogger.contains 'Horizon.S52E16' }
    end
  end

  context '#ut_names' do

    let(:cmd) { '.tnames' }

    it "display names of torrents in uTorrent" do
      plugin.ut_names args
      expect { CaptureLogger.contains 'Horizon.S52E16' }
    end
  end

  context '#ut_torrent_details' do

    let(:cmd) { '.tdetails' }

    it "display torrent details" do
      TorrentProcessor::Plugin::UTPlugin.any_instance.stub(:getInput).and_return('0')
      plugin.ut_torrent_details args
      expect { CaptureLogger.contains 'Horizon.S52E16' }
    end
  end

  context '#ut_list_query' do

    let(:cmd) { '.listquery' }

    it "return response output of list query" do
      plugin.ut_list_query args
      expect { CaptureLogger.contains '520023045, 0, 0, 0, 0, 0, "TV",' }
    end
  end
end
