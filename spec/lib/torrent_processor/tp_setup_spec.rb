require 'spec_helper'
include TorrentProcessor

describe TPSetup do

  let(:data_dir) { 'spec/data' }

  let(:data_cfg_file_v0) do
    File.join(data_dir, 'config-v0.yml')
  end

  let(:data_cfg_file_v1) do
    File.join(data_dir, 'config-v1.yml')
  end

  let(:data_cfg_file_v2) do
    File.join(data_dir, 'config-v2.yml')
  end

  let(:setup_cfg_v0) do
    blocking_file_delete cfg_path
    cp data_cfg_file_v0, cfg_path
  end

  let(:setup_cfg_v1) do
    blocking_file_delete cfg_path
    cp data_cfg_file_v1, cfg_path
  end

  let(:setup_cfg_v2) do
    blocking_file_delete cfg_path
    cp data_cfg_file_v2, cfg_path
  end

  subject(:setup)   { TPSetup.new(args) }

  # Common set of args passed to plugins by the console object.
  let(:args) do
    {
      #:logger   => SimpleLogger,
      :database => Mocks.db,
    }
  end

  context "#new" do

    it "instantiates without an exception" do
      #expect(setup.setup_config)
      setup
    end
  end

  context 'upgrading' do

    context '#config_needs_upgrade?' do

      before(:all) do
        rm_r spec_tmp_dir('tpsetup/needs_upgrade')
      end

      before(:each) do
        allow_any_instance_of(TorrentProcessor::TPSetup).to receive(:app_data_path).and_return(local_app_data_path)
      end

      context 'v0 configuration file has not been upgraded' do

        let(:tmp_dir) { spec_tmp_dir 'tpsetup/needs_upgrade/v0' }

        let(:local_app_data_path) do
          tmp_dir
        end

        let(:cfg_path) do
          tmp_dir + 'config.yml'
        end

        it 'returns true' do
          setup_cfg_v0
          expect(setup.config_needs_upgrade?).to eq true
        end
      end

      context 'v1 configuration file has not been upgraded' do

        let(:tmp_dir) { spec_tmp_dir 'tpsetup/needs_upgrade/v1' }

        let(:local_app_data_path) do
          tmp_dir
        end

        let(:cfg_path) do
          tmp_dir + 'config.yml'
        end

        it 'returns true' do
          setup_cfg_v1

          expect(setup.config_needs_upgrade?).to eq true
        end
      end

      context 'configuration file has been upgraded' do

        let(:tmp_dir) { spec_tmp_dir 'tpsetup/upgraded/v2' }

        let(:local_app_data_path) do
          tmp_dir
        end

        let(:cfg_path) do
          tmp_dir + 'config.yml'
        end

        it 'returns false' do
          setup_cfg_v2
          expect(setup.config_needs_upgrade?).to eq false
        end
      end
    end # context #config_needs_upgrade?

    context 'migrations' do

      before(:all) do
        rm_r spec_tmp_dir('tpsetup/migrate')
      end

      context '#migrate_to_v1' do

        context 'migrates v0 config to v1' do

          let(:tmp_dir) { spec_tmp_dir 'tpsetup/migrate/v1' }

          let(:local_app_data_path) do
            tmp_dir
          end

          let(:cfg_path) do
            tmp_dir + 'config.yml'
          end

          before(:each) do
            allow_any_instance_of(TorrentProcessor::TPSetup).to receive(:app_data_path).and_return(local_app_data_path)
          end

          it 'replaces appPath with app_path' do
            setup_cfg_v0
            setup.migrate_to_v1 local_app_data_path

            expect(in_file?('appPath', cfg_path)).to eq false
          end
        end
      end

      context '#migrate_to_v2' do

        context 'migrates v0 config to v2' do

          let(:tmp_dir) { spec_tmp_dir 'tpsetup/migrate/v2' }

          let(:local_app_data_path) do
            tmp_dir
          end

          let(:cfg_path) do
            tmp_dir + 'config.yml'
          end

          before(:each) do
            allow_any_instance_of(TorrentProcessor::TPSetup).to receive(:app_data_path).and_return(local_app_data_path)
          end

          it 'creates "version" entry with value of 2' do
            setup_cfg_v0
            setup.migrate_to_v2 local_app_data_path

            expect(in_file?('version: 2', cfg_path)).to eq true
          end

          it 'creates "backend" entry with default value of :utorrent' do
            setup_cfg_v0
            setup.migrate_to_v2 local_app_data_path

            expect(in_file?('backend: :utorrent', cfg_path)).to eq true
          end
        end
      end
    end

    context '#backup_config' do

      before(:all) do
        rm_r spec_tmp_dir('tpsetup/backup')
      end

      before(:each) do
        allow_any_instance_of(TorrentProcessor::TPSetup).to receive(:app_data_path).and_return(local_app_data_path)
      end

      let(:tmp_dir) { spec_tmp_dir 'tpsetup/backup' }

      let(:local_app_data_path) do
        tmp_dir
      end

      let(:cfg_path) do
        tmp_dir + 'config.yml'
      end

      it 'creates a timestamped backup of the current config file' do
        setup_cfg_v0

        setup.backup_config
        expect(Dir[local_app_data_path + '*_bak.yml'].size).to eq 1
      end
    end # context #backup_config
  end
end

