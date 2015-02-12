##############################################################################
# File::    ut_plugin_spec.rb
# Purpose:: uTorrent Plugin specification
#
# Author::    Jeff McAffee 2014-01-14
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'spec_helper'

include TorrentProcessor::Plugin

describe UTPlugin do

  before(:each) { CaptureLogger.reset }

  subject(:plugin) { UTPlugin.new }

  let(:args) do
    {
      :cmd      => cmd,
      :logger   => CaptureLogger,
      :utorrent => Mocks.utorrent,
      :database => Mocks.db,
    }
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
      allow_any_instance_of(TorrentProcessor::Plugin::UTPlugin).to receive(:getInput).and_return('0')
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
      allow_any_instance_of(TorrentProcessor::Plugin::UTPlugin).to receive(:getInput).and_return('1')
      plugin.ut_torrent_details args
      expect { CaptureLogger.contains 'availability       : 65536' }
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
