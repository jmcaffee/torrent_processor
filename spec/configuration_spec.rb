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

  context '.configuration' do

    it 'returns a configuration object' do
      expect(TorrentProcessor.configuration).to_not be nil
    end

    context '#utorrent' do

      it 'returns a UTorrentConfiguration object' do
        expect(TorrentProcessor.configuration.utorrent).to_not be nil
      end

      context '#dir_completed_download' do

        let(:test_dir)  { 'some/test/dir' }

        it 'sets and retains a value' do
          TorrentProcessor.configure do |config|
            config.utorrent.dir_completed_download = test_dir
          end

          expect(TorrentProcessor.configuration.utorrent.dir_completed_download).to eq test_dir
        end
      end

      context '#seed_ratio' do

        let(:test_ratio)  { '1500' }

        it 'sets and retains a value' do
          TorrentProcessor.configure do |config|
            config.utorrent.seed_ratio = test_ratio
          end

          expect(TorrentProcessor.configuration.utorrent.seed_ratio).to eq test_ratio
        end
      end

      context '.save_configuration' do

        let(:cfg_file) { 'tmp/spec/save-config.yml' }

        it 'writes the current configuration to disk' do
          TorrentProcessor.configure do |config|
            config.utorrent.ip = '127.0.0.1'
            config.utorrent.port = 8080
            config.utorrent.user = 'ut_user'
            config.utorrent.pass = 'ut_pass'
            config.utorrent.dir_completed_download = 'tmp/spec/configuration'
            config.utorrent.seed_ratio = 1500

            config.tmdb.api_key = 'apikey'
            config.tmdb.language = 'es'
          end

          blocking_file_delete cfg_file
          TorrentProcessor.save_configuration cfg_file

          contents = File.read cfg_file
          expect(contents.include?('127.0.0.1')).to be true
        end
      end

      context '.load_configuration' do

        let(:cfg_file) { 'tmp/spec/load-config.yml' }

        let(:config_file) do
          TorrentProcessor.configure do |config|
            config.utorrent.ip = '127.0.0.1'
            config.utorrent.port = 8080
            config.utorrent.user = 'ut_user'
            config.utorrent.pass = 'ut_pass'
            config.utorrent.dir_completed_download = 'tmp/spec/configuration'
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
          expect(cfg.utorrent.dir_completed_download).to eq 'tmp/spec/configuration'
          expect(cfg.utorrent.seed_ratio).to eq 1500
          expect(cfg.tmdb.api_key).to eq 'apikey'
          expect(cfg.tmdb.language).to eq 'es'
        end
      end
    end
  end
end
