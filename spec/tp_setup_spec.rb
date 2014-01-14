require 'spec_helper'
include TorrentProcessor

describe TPSetup do

      let(:data_dir) { 'spec/data' }

      let(:old_cfg_stub) do
        cfg = {}
        #tmp_path = File.absolute_path(File.join(File.dirname(__FILE__), '../../tmp/spec/tpsetup'))
        cfg[:appPath] = tmp_path
        cfg[:version]  = TorrentProcessor::VERSION
        cfg[:logging]  = false
        cfg[:filters] = {}
        cfg[:ip] = '127.0.0.1'
        cfg[:port] = '8082'
        cfg[:user] = 'testuser'
        cfg[:pass] = 'testpass'
        cfg[:tmdb_api_key] = 'apikey'
        cfg[:target_movies_path] = File.join(tmp_path, 'movies_final')
        cfg[:can_copy_start_time] = "00:00"
        cfg[:can_copy_stop_time] = "23:59"
        cfg
      end

      let(:new_cfg_stub) do
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

        cfg.tmdb.api_key              = 'apikey'
        cfg.tmdb.language             = 'en'
        cfg.tmdb.target_movies_path   = File.join(tmp_path, 'movies_final')
        cfg.tmdb.can_copy_start_time  = "00:00"
        cfg.tmdb.can_copy_stop_time   = "23:59"
        cfg
      end

      let(:tmp_path) do
        #File.absolute_path(File.join(File.dirname(__FILE__), '../../tmp/spec/tpsetup'))
        File.absolute_path('tmp/spec/tpsetup')
      end

      let(:controller_stub) do
        obj = double('controller')
        obj.stub(:cfg) do
          old_cfg_stub
        end
        obj
      end


      subject(:setup)   { TPSetup.new(controller_stub) }


  context "#new" do

    it "instantiates without an exception" do
      #expect(setup.setup_config)
      setup
    end
  end

  context 'upgrading' do

    context '#config_needs_upgrade?' do

      context 'configuration file has not been upgraded' do

        it 'returns true' do
          expect(setup.config_needs_upgrade?).to eq true
        end
      end

      context 'configuration file has been upgraded' do

        let(:controller_stub) do
          obj = double('controller')
          obj.stub(:cfg) do
            new_cfg_stub
          end
          obj
        end

        it 'returns false' do
          expect(setup.config_needs_upgrade?).to eq false
        end
      end
    end # context #config_needs_upgrade?

    context '#backup_config' do

      before(:each) do
        mkpath tmp_path
        targets = Dir[File.join(tmp_path, '*.yml')]
        targets.each do |target|
          rm target if File.exists?(target)
        end

        old_config_yml = File.join(tmp_path, 'config.yml')
        rm old_config_yml if File.exists?(old_config_yml)
        cp File.join(data_dir, 'old_config.yml'), File.join(tmp_path, 'config.yml')
      end

      it 'creates a timestamped backup of the current config file' do
        setup.backup_config
        expect(Dir[tmp_path + '/*_bak.yml'].size).to be 1
      end
    end # context #backup_config

    context '#upgrade_config' do

      before(:each) do
        mkpath tmp_path
        targets = Dir[File.join(tmp_path, '*.yml')]
        targets.each do |target|
          rm target if File.exists?(target)
        end

        old_config_yml = File.join(tmp_path, 'config.yml')
        rm old_config_yml if File.exists?(old_config_yml)
        cp File.join(data_dir, 'old_config.yml'), File.join(tmp_path, 'config.yml')
      end

      it 'replaces old config file with new (upgraded) config file' do
        setup.upgrade_config(tmp_path)
        TorrentProcessor.load_configuration File.join(tmp_path, 'config.yml')
        new_config = TorrentProcessor.configuration

        expect(new_config.utorrent.port).to eq '8082'
      end
    end # context #backup_config
  end
end
