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

  let(:controller_stub) do
    obj = double('controller')
    obj.stub(:cfg) { cfg_stub }
    obj.stub(:database) { db_stub }
    obj
  end

  let(:db_stub) do
    obj = double('database')
    obj.stub(:close) { true }
    obj
  end

  let(:cfg_stub) do
    cfg = TorrentProcessor.configuration
    #tmp_path = File.absolute_path(File.join(File.dirname(__FILE__), '../../tmp/spec/tpsetup'))
    cfg.app_path          = tmp_path
    cfg.logging           = false
    cfg.max_log_size      = 0
    cfg.log_dir           = tmp_path
    cfg.tv_processing     = File.join(tmp_path, 'media/tv')
    cfg.movie_processing  = File.join(tmp_path, 'media/movies')
    cfg.other_processing  = File.join(tmp_path, 'media/other')
    cfg.filters           = {}

    cfg.utorrent.ip                     = '192.168.1.103'
    cfg.utorrent.port                   = '8082'
    cfg.utorrent.user                   = 'admin'
    cfg.utorrent.pass                   = 'abc'
    cfg.utorrent.dir_completed_download = File.join(tmp_path, 'torrents/completed')
    cfg.utorrent.seed_ratio             = 0

    cfg.tmdb.api_key              = '***REMOVED***'
    cfg.tmdb.language             = 'en'
    cfg.tmdb.target_movies_path   = File.join(tmp_path, 'movies_final')
    cfg.tmdb.can_copy_start_time  = "00:00"
    cfg.tmdb.can_copy_stop_time   = "23:59"
    cfg
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

    obj.stub(:parseResponse) do
      {}
    end

    obj.stub(:settings) do
      {}
    end

    obj
  end

  let(:args) do
    {
      :cmd      => cmd,
      :logger   => SimpleLogger,
      :utorrent => ut_stub,
      :database => db_stub,
      #:logger   => Runtime.service.logger,
      #:utorrent => Runtime.service.utorrent,
      #:database => Runtime.service.database,
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
