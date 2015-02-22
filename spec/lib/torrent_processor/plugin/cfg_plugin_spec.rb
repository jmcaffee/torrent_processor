##############################################################################
# File::    cfg_plugin_spec.rb
# Purpose:: Configuration Plugin specification
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
    spec_tmp_dir('cfg_plugin').to_s
  end

  # Common set of args passed to plugins by the console object.
  let(:args) do
    {
      :cmd      => cmd,
      :logger   => CaptureLogger,
      :utorrent => Mocks.utorrent,
      :database => Mocks.db,
    }
  end

  context 'configuration commands' do

      before(:each) do
        TorrentProcessor.configuration.app_path = tmp_path
        TorrentProcessor.configuration.filters = {}
        TorrentProcessor.save_configuration
      end

    context "uTorrent backend" do

      before(:each) do
        TorrentProcessor.configuration.backend = :utorrent
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
    end

    context "qbTorrent backend" do

      before(:each) do
        TorrentProcessor.configuration.backend = :qbtorrent
        TorrentProcessor.save_configuration
      end

      context '#cfg_user' do

        let(:cmd) { '.user bar' }

        it "configure qbTorrent user name" do
          plugin.cfg_user args
          expect(TorrentProcessor.configuration.qbtorrent.user).to eq 'bar'
        end
      end

      context '#cfg_pwd' do

        let(:cmd) { '.pwd baz' }

        it "configure qbTorrent password" do
          plugin.cfg_pwd args
          expect(TorrentProcessor.configuration.qbtorrent.pass).to eq 'baz'
        end
      end

      context '#cfg_ip' do

        let(:cmd) { '.ip 10.0.0.2' }

        it "configure qbTorrent IP address" do
          plugin.cfg_ip args
          expect(TorrentProcessor.configuration.qbtorrent.ip).to eq '10.0.0.2'
        end
      end

      context '#cfg_port' do

        let(:cmd) { '.port 10999' }

        it "configure qbTorrent port" do
          plugin.cfg_port args
          expect(TorrentProcessor.configuration.qbtorrent.port).to eq '10999'
        end
      end
    end

    context '#cfg_addfilter' do

      context 'with args' do
        let(:cmd) { '.addfilter my.torrent.tracker 1000' }

        it "add a tracker seed filter" do
          plugin.cfg_addfilter args
          expect(TorrentProcessor.configuration.filters['my.torrent.tracker']).to eq '1000'
        end
      end

      context 'without args' do
        let(:cmd) { '.addfilter' }

        it "displays a helpful message" do
          CaptureLogger.reset

          plugin.cfg_addfilter args
          expect(CaptureLogger.messages.include?('Usage: .addfilter some.tracker.url ratio')).to be true
        end
      end
    end

    context '#cfg_delfilter' do

      context 'with args' do
        let(:cmd) { '.delfilter my.torrent.tracker' }

        before(:each) do
          TorrentProcessor.configuration.filters['my.torrent.tracker'] = '1500'
        end

        it "delete a tracker seed filter" do
          plugin.cfg_delfilter args
          expect(TorrentProcessor.configuration.filters['my.torrent.tracker']).to be nil
        end
      end

      context 'without args' do
        let(:cmd) { '.delfilter' }

        it "displays a helpful message" do
          plugin.cfg_delfilter args
          expect(CaptureLogger.messages.include?('Usage: .delfilter some.tracker.url')).to be true
          expect(CaptureLogger.messages.include?('       use .listfilters to see a list of current filters')).to be true
        end
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
