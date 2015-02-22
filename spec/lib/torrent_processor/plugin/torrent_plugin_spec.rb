##############################################################################
# File::    torrent_plugin_spec.rb
# Purpose:: Torrent App Plugin specification
#
# Author::    Jeff McAffee 2014-01-14
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'spec_helper'

include TorrentProcessor::Plugin

describe TorrentPlugin do

  before(:each) { CaptureLogger.reset }

  subject(:plugin) { TorrentPlugin.new }

  let(:args) do
    {
      :cmd        => cmd,
      :logger     => CaptureLogger,
      :webui      => Mocks.utorrent,
      :webui_type => :utorrent,
      :database   => Mocks.db,
    }
  end

  context '#cmd_test_connection' do

    let(:cmd) { '.testcon' }

    it "tests the torrent app connection" do
      plugin.cmd_test_connection args
    end
  end

  context '#t_settings' do

    let(:cmd) { '.tsettings' }

    it "returns current torrent app settings" do
      plugin.cmd_settings args
    end
  end

  context '#t_jobprops' do

    let(:cmd) { '.jobprops' }

    it "returns current torrent app job properties" do
      allow_any_instance_of(TorrentProcessor::Plugin::TorrentPlugin).to receive(:getInput).and_return('0')
      plugin.cmd_jobprops args
      expect { CaptureLogger.contains 'Horizon.S52E16' }
    end
  end

  context '#cmd_list' do

    let(:cmd) { '.tlist' }

    it "returns a list of torrents torrent app is monitoring" do
      plugin.cmd_list args
      expect { CaptureLogger.contains 'Horizon.S52E16' }
    end
  end

  context '#cmd_names' do

    let(:cmd) { '.tnames' }

    it "display names of torrents in torrent app" do
      plugin.cmd_names args
      expect { CaptureLogger.contains 'Horizon.S52E16' }
    end
  end

  context '#cmd_torrent_details' do

    let(:cmd) { '.tdetails' }

    it "display torrent details" do
      allow_any_instance_of(TorrentProcessor::Plugin::TorrentPlugin).to receive(:getInput).and_return('1')
      plugin.cmd_torrent_details args
      expect { CaptureLogger.contains 'availability       : 65536' }
    end
  end

  context '#cmd_list_query' do

    let(:cmd) { '.listquery' }

    it "return response output of list query" do
      plugin.cmd_list_query args
      expect { CaptureLogger.contains '520023045, 0, 0, 0, 0, 0, "TV",' }
    end
  end
end
