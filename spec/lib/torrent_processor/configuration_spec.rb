##############################################################################
# File::    configuration_spec.rb
# Purpose:: TorrentProcessor::configuration specification
# 
# Author::    Jeff McAffee 01/07/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'spec_helper'

describe TorrentProcessor do

  let(:tmp_path) do
    pth = File.absolute_path('tmp/spec/configuration')
    mkpath pth
    pth
  end

  context '.configuration' do

    subject do
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

      cfg.utorrent.ip                     = '127.0.0.1'
      cfg.utorrent.port                   = '8081'
      cfg.utorrent.user                   = 'testuser'
      cfg.utorrent.pass                   = 'testpass'
      cfg.utorrent.dir_completed_download = File.join(tmp_path, 'torrents/completed')
      cfg.utorrent.seed_ratio             = 0

      cfg.tmdb.api_key              = ENV['TMDB_API_KEY']
      cfg.tmdb.language             = 'en'
      cfg.tmdb.target_movies_path   = File.join(tmp_path, 'movies_final')
      cfg.tmdb.can_copy_start_time  = "00:00"
      cfg.tmdb.can_copy_stop_time   = "23:59"
      cfg
    end

    it 'returns a configuration object' do
      expect(TorrentProcessor.configuration).to_not be nil
    end

    its(:app_path) { should == tmp_path }

    its(:logging) { should == false }

    its(:max_log_size) { should == 0 }

    its(:log_dir) { should == tmp_path }

    its(:tv_processing) { should == File.join(tmp_path, 'media/tv') }

    its(:movie_processing) { should == File.join(tmp_path, 'media/movies') }

    its(:other_processing) { should == File.join(tmp_path, 'media/other') }

    its(:filters) { should == {} }



    context '#utorrent' do

      subject do
        TorrentProcessor.configure do |cfg|
          cfg.utorrent.ip                     = '127.0.0.1'
          cfg.utorrent.port                   = '8081'
          cfg.utorrent.user                   = 'testuser'
          cfg.utorrent.pass                   = 'testpass'
          cfg.utorrent.dir_completed_download = File.join(tmp_path, 'torrents/completed')
          cfg.utorrent.seed_ratio             = 0
        end
        TorrentProcessor.configuration.utorrent
      end

      its(:ip) { should == '127.0.0.1' }

      its(:port) { should == '8081' }

      its(:user) { should == 'testuser' }

      its(:pass) { should == 'testpass' }

      its(:dir_completed_download) { should == File.join(tmp_path, 'torrents/completed') }

      its(:seed_ratio) { should == 0 }

      it 'returns a UTorrentConfiguration object' do
        expect(TorrentProcessor.configuration.utorrent).to_not be nil
      end
    end # context #utorrent

    context '#tmdb' do

      subject do
        TorrentProcessor.configure do |cfg|
          cfg.tmdb.api_key              = 'apikey'
          cfg.tmdb.language             = 'es'
          cfg.tmdb.target_movies_path   = File.join(tmp_path, 'movies_final')
          cfg.tmdb.can_copy_start_time  = '08:30'
          cfg.tmdb.can_copy_stop_time   = '09:45'
        end
        TorrentProcessor.configuration.tmdb
      end

      its(:api_key) { should == 'apikey' }

      its(:language) { should == 'es' }

      its(:target_movies_path) { should == File.join(tmp_path, 'movies_final') }

      its(:can_copy_start_time) { should == '08:30' }

      its(:can_copy_stop_time) { should == '09:45' }

      it 'returns a TMdbConfiguration object' do
        expect(TorrentProcessor.configuration.tmdb).to_not be nil
      end
    end # context #tmdb
  end # context .configuration

  context '.save_configuration' do

    let(:cfg_file)          { 'tmp/spec/save-config.yml' }
    let(:cfg_file_default)  { File.join(tmp_path, 'config.yml') }

    context 'given a specific filename' do

      it 'writes the current configuration to disk' do
        TorrentProcessor.configure do |config|
          config.utorrent.ip = '127.0.0.1'
          config.utorrent.port = 8080
          config.utorrent.user = 'ut_user'
          config.utorrent.pass = 'ut_pass'
          config.utorrent.dir_completed_download = tmp_path
          config.utorrent.seed_ratio = 1500

          config.tmdb.api_key = 'apikey'
          config.tmdb.language = 'es'
        end

        blocking_file_delete cfg_file
        TorrentProcessor.save_configuration cfg_file

        contents = File.read cfg_file
        expect(contents.include?('127.0.0.1')).to be true
      end
    end # context given a specific filename

    context 'no filename specified' do

      context 'app_path is empty' do

        it 'raises exception' do
          TorrentProcessor.configure do |config|
            config.app_path = ''
          end

          blocking_file_delete cfg_file_default
          expect { TorrentProcessor.save_configuration }.to raise_exception
        end
      end # context app_path is empty

      context 'app_path is nil' do

        it 'writes the current configuration to disk' do
          TorrentProcessor.configure do |config|
            config.app_path = nil
          end

          blocking_file_delete cfg_file_default
          expect { TorrentProcessor.save_configuration }.to raise_exception
        end
      end # context app_path is nil

      context 'app_path is populated' do

        it 'writes the current configuration to disk' do
          TorrentProcessor.configure do |config|
            config.app_path = tmp_path
          end

          blocking_file_delete cfg_file_default
          expect { TorrentProcessor.save_configuration }.to_not raise_exception

          contents = File.read cfg_file
          expect(contents.include?(tmp_path)).to be true
        end
      end # context app_path is nil
    end # context no filename specified
  end # context .save_configuration

  context '.load_configuration' do

    let(:cfg_file) { 'tmp/spec/load-config.yml' }

    let(:config_file) do
      TorrentProcessor.configure do |config|
        config.utorrent.ip = '127.0.0.1'
        config.utorrent.port = 8080
        config.utorrent.user = 'ut_user'
        config.utorrent.pass = 'ut_pass'
        config.utorrent.dir_completed_download = tmp_path
        config.utorrent.seed_ratio = 1500

        config.tmdb.api_key = 'apikey'
        config.tmdb.language = 'es'
      end

      blocking_file_delete cfg_file
      TorrentProcessor.save_configuration cfg_file

      TorrentProcessor.configure do |config|
        config.utorrent.ip = nil
        config.utorrent.port = nil
        config.utorrent.user = nil
        config.utorrent.pass = nil
        config.utorrent.dir_completed_download = nil
        config.utorrent.seed_ratio = nil

        config.tmdb.api_key = nil
        config.tmdb.language = nil
      end
    end

    let(:cfg) { TorrentProcessor.configuration }

    it 'reads the configuration data from disk' do
      config_file

      TorrentProcessor.load_configuration cfg_file

      expect(cfg.utorrent.ip).to eq '127.0.0.1'
      expect(cfg.utorrent.port).to eq 8080
      expect(cfg.utorrent.user).to eq 'ut_user'
      expect(cfg.utorrent.pass).to eq 'ut_pass'
      expect(cfg.utorrent.dir_completed_download).to eq tmp_path
      expect(cfg.utorrent.seed_ratio).to eq 1500
      expect(cfg.tmdb.api_key).to eq 'apikey'
      expect(cfg.tmdb.language).to eq 'es'
    end
  end # context .load_configuration
end
