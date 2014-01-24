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

describe CfgPlugin do

  subject(:plugin) { CfgPlugin.new }

  let(:tmp_path) do
    pth = 'tmp/spec/cfg_plugin'
    mkpath pth
    pth
  end

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

    obj.stub(:settings) do
      {}
    end

    obj.stub(:sendGetQuery) do
      {}
    end

    obj
  end

  # Common set of args passed to plugins by the console object.
  let(:args) do
    {
      :cmd      => cmd,
      #:logger   => SimpleLogger,
      :utorrent => ut_stub,
      :database => db_stub,
    }
  end

  context 'configuration commands' do

      before(:each) do
        TorrentProcessor.configuration.app_path = tmp_path
        TorrentProcessor.configuration.filters = {}
        TorrentProcessor.save_configuration
      end

    context '#cfg_user' do

      let(:cmd) { '.user foo' }

      it "configure uTorrent user name" do
        plugin.cfg_user args
        expect(TorrentProcessor.configuration.utorrent.user).to eq 'foo'
      end
    end

    context '#cfg_pwd' do

      let(:cmd) { '.pwd bar' }

      it "configure uTorrent password" do
        plugin.cfg_pwd args
        expect(TorrentProcessor.configuration.utorrent.pass).to eq 'bar'
      end
    end

    context '#cfg_ip' do

      let(:cmd) { '.ip 10.0.0.1' }

      it "configure uTorrent IP address" do
        plugin.cfg_ip args
        expect(TorrentProcessor.configuration.utorrent.ip).to eq '10.0.0.1'
      end
    end

    context '#cfg_port' do

      let(:cmd) { '.port 10625' }

      it "configure uTorrent port" do
        plugin.cfg_port args
        expect(TorrentProcessor.configuration.utorrent.port).to eq '10625'
      end
    end

    context '#cfg_addfilter' do

      let(:cmd) { '.addfilter my.torrent.tracker 1000' }

      it "add a tracker seed filter" do
        plugin.cfg_addfilter args
        expect(TorrentProcessor.configuration.filters['my.torrent.tracker']).to eq '1000'
      end
    end

    context '#cfg_delfilter' do

      let(:cmd) { '.delfilter my.torrent.tracker' }

      before(:each) do
        TorrentProcessor.configuration.filters['my.torrent.tracker'] = '1500'
      end

      it "delete a tracker seed filter" do
        plugin.cfg_delfilter args
        expect(TorrentProcessor.configuration.filters['my.torrent.tracker']).to be nil
      end
    end

    context '#cfg_listfilters' do

      let(:cmd) { '.listfilters' }

      before(:each) do
        TorrentProcessor.configure do |config|
          config.filters['my.torrent.tracker']  = '1500'
          config.filters['foo.bar.tracker']     = '0'
        end
      end

      it "list current tracker filters" do
        plugin.cfg_listfilters args
      end
    end
  end # context configuration commands
end
