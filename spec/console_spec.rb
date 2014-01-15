##############################################################################
# File::    console_spec.rb
# Purpose:: Console specification
#
# Author::    Jeff McAffee 01/08/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

###
# FIXME: This is a 'bad' specification. It should only test the in/out interface
# and it actually contains many tests touching dependent plugins.
# This should be fixed.
###


require 'spec_helper'

include TorrentProcessor

describe Console do

  subject(:console) { Console.new(controller_stub) }

  let(:tmp_path) do
    pth = 'tmp/spec/console'
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

  context '#new' do

    it 'instantiates a console object' do
      Console.new(controller_stub)
    end
  end

  context '#execute' do

    it 'starts the console' do
      console.execute
    end
  end

  context '#process_cmd' do

    context 'uTorrent commands' do

      context 'cmd: .testcon' do

        it "'.testcon' tests the uTorrent connection" do
          console.process_cmd '.testcon'
        end
      end

      context 'cmd: .utsettings' do

        it "'.utsettings' returns current uTorrent settings" do
          console.process_cmd '.utsettings'
        end
      end

      context 'cmd: .jobprops' do

        it "'.jobprops' returns current uTorrent job properties" do
          console.process_cmd '.jobprops'
        end
      end

      context 'cmd: .tlist' do

        it "'.tlist' returns a list of torrents uTorrent is monitoring" do
          console.process_cmd '.tlist'
        end
      end

      context 'cmd: .tnames' do

        it "'.tnames' display names of torrents in uTorrent" do
          console.process_cmd '.tnames'
        end
      end

      context 'cmd: .tdetails' do

        it "'.tdetails' display torrent details" do
          console.process_cmd '.tdetails'
        end
      end

      context 'cmd: .listquery' do

        it "'.listquery' return response output of list query" do
          console.process_cmd '.listquery'
        end
      end
    end # context uTorrent commands

    context 'TMdb comands' do

      TorrentProcessor.configure do |config|
        config.tmdb.api_key = '***REMOVED***'
      end

      context 'cmd: .tmdbtestcon' do

        it "'.tmdbtestcon' tests the TMdb connection" do
          console.process_cmd '.tmdbtestcon'
        end
      end

      context 'cmd: .tmdbmoviesearch' do

        it "'.tmdbmoviesearch' searches for a movie" do
          console.process_cmd '.tmdbmoviesearch fight club'
          #console.process_cmd '.tmdbmoviesearch'
        end
      end
    end
  end
end
