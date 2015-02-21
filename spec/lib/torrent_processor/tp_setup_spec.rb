require 'spec_helper'
include TorrentProcessor

def delete_all_configs
  targets = Dir[File.join(app_data_path, '*.yml')]
  targets.each do |target|
    blocking_file_delete(target) if File.exists?(target)
  end
end

describe TPSetup do

  let(:tmp_path) do
    pth = spec_tmp_path 'tpsetup'
    pth.to_s
  end

  let(:data_dir) { 'spec/data' }

  let(:cfg_path) do
    File.join(app_data_path, 'config.yml')
  end

  let(:app_data_path) do
    appdata = ''
    if Ktutils::OS.windows?
      appdata = ENV['APPDATA'].gsub('\\', '/')
      appdata = File.join(appdata, 'torrentprocessor')
    else
      appdata = ENV['HOME']
      appdata = File.join(appdata, '.torrentprocessor')
    end
    appdata
  end

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

      context 'v0 configuration file has not been upgraded' do

        it 'returns true' do
          setup_cfg_v0
          expect(setup.config_needs_upgrade?).to eq true
        end
      end

      context 'v1 configuration file has not been upgraded' do

        it 'returns true' do
          setup_cfg_v1
          expect(setup.config_needs_upgrade?).to eq true
        end
      end

      context 'configuration file has been upgraded' do

        it 'returns false' do
          setup_cfg_v2
          expect(setup.config_needs_upgrade?).to eq false
        end
      end
    end # context #config_needs_upgrade?

    context '#migrate_to_v1' do

      context 'migrates v0 config to v1' do

        it 'replaces appPath with app_path' do
          setup_cfg_v0
          setup.migrate_to_v1 app_data_path

          expect(in_file?('appPath', cfg_path)).to eq false
        end
      end
    end

    context '#migrate_to_v2' do

      context 'migrates v0 config to v2' do

        it 'creates "version" entry with value of 2' do
          setup_cfg_v0
          setup.migrate_to_v2 app_data_path

          expect(in_file?('version: 2', cfg_path)).to eq true
        end

        it 'creates "backend" entry with default value of :utorrent' do
          setup_cfg_v0
          setup.migrate_to_v2 app_data_path

          expect(in_file?('backend: :utorrent', cfg_path)).to eq true
        end
      end
    end

    context '#backup_config' do

      before(:each) do
        delete_all_configs
      end

      it 'creates a timestamped backup of the current config file' do
        setup_cfg_v0

        setup.backup_config
        expect(Dir[app_data_path + '/*_bak.yml'].size).to be 1
      end
    end # context #backup_config
  end
end
