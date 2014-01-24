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
    pth = 'tmp/spec/tpsetup'
    mkpath pth
    pth
  end

  let(:data_dir) { 'spec/data' }

  let(:db_stub) do
    obj = double('database')
    obj.stub(:close) { true }
    obj
  end

  let(:cfg_path) do
    File.join(app_data_path, 'config.yml')
  end

  let(:app_data_path) do
    appdata = ENV['APPDATA'].gsub('\\', '/')
    File.join(appdata, 'torrentprocessor')
  end

  let(:data_old_cfg_file) do
    File.join(data_dir, 'old_config.yml')
  end

  let(:data_new_cfg_file) do
    File.join(data_dir, 'new_config.yml')
  end

  let(:setup_old_cfg) do
    blocking_file_delete cfg_path
    cp data_old_cfg_file, cfg_path
  end

  let(:setup_new_cfg) do
    blocking_file_delete cfg_path
    cp data_new_cfg_file, cfg_path
  end

  subject(:setup)   { TPSetup.new(args) }

  # Common set of args passed to plugins by the console object.
  let(:args) do
    {
      #:logger   => SimpleLogger,
      :database => db_stub,
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

      context 'configuration file has not been upgraded' do

        it 'returns true' do
          setup_old_cfg
          expect(setup.config_needs_upgrade?).to eq true
        end
      end

      context 'configuration file has been upgraded' do

        it 'returns false' do
          setup_new_cfg
          expect(setup.config_needs_upgrade?).to eq false
        end
      end
    end # context #config_needs_upgrade?

    context '#backup_config' do

      before(:each) do
        delete_all_configs
      end

      it 'creates a timestamped backup of the current config file' do
        setup_old_cfg

        setup.backup_config
        expect(Dir[app_data_path + '/*_bak.yml'].size).to be 1
      end
    end # context #backup_config

    context '#upgrade_config' do

      before(:each) do
        delete_all_configs
      end

      it 'replaces old config file with new (upgraded) config file' do
        setup_old_cfg

        setup.upgrade_config(app_data_path)
        TorrentProcessor.load_configuration cfg_path

        expect(setup.config_needs_upgrade?).to eq false
      end
    end # context #backup_config
  end
end
