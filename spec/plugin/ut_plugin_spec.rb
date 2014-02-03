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

  subject(:plugin) { UTPlugin.new }

  let(:tmp_path) { 'tmp/spec/ut_plugin' }

  let(:db_stub) do
    obj = double('database')
    obj.stub(:close) { true }
    obj
  end

  let(:ut_stub) do
    obj = double('utorrent')
    obj.stub(:get_torrent_list) do
      {}
    end

    obj.stub(:torrents) do
      {}
    end

    obj.stub(:get_utorrent_settings) do
      {}
    end

    obj.stub(:settings) do
      {}
    end

    obj.stub(:sendGetQuery) do
      {}
    end

    obj
  end

  let(:args) do
    {
      :cmd      => cmd,
      #:logger   => SimpleLogger,
      :utorrent => ut_stub,
      :database => db_stub,
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
      plugin.ut_jobprops args
    end
  end

  context '#ut_list' do

    let(:cmd) { '.tlist' }

    it "returns a list of torrents uTorrent is monitoring" do
      plugin.ut_list args
    end
  end

  context '#ut_names' do

    let(:cmd) { '.tnames' }

    it "display names of torrents in uTorrent" do
      plugin.ut_names args
    end
  end

  context '#ut_torrent_details' do

    let(:cmd) { '.tdetails' }

    it "display torrent details" do
      plugin.ut_torrent_details args
    end
  end

  context '#ut_list_query' do

    let(:cmd) { '.listquery' }

    it "return response output of list query" do
      plugin.ut_list_query args
    end
  end
end
