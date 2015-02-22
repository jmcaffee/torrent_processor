require 'spec_helper'

include TorrentProcessor

describe TorrentApp do

  context "#new" do

    it "can be instantiated" do
      obj = TorrentApp.new({})
    end

    it "default webui type is :utorrent" do
      obj = TorrentApp.new({})
      expect(obj.webui_type).to eq :utorrent
    end

    it ":webui_type must be provided if passing :webui" do
      expect{ TorrentApp.new(:webui => Mocks.utorrent) }.to raise_exception
    end

    it "unrecognized :webui_type raises an exception" do
      obj = TorrentApp.new(:webui_type => :unknown)
      expect{ obj.seed_ratio }.to raise_exception("Unknown webui_type: :unknown")
    end
  end

  let(:backend_mock) { Mocks.qbtorrent }

  let(:init_args) do
    {
      :cfg        => Mocks.cfg('torrent_app'),
      :webui      => backend_mock,
      :webui_type => :qbtorrent,
      :database   => Mocks.db,
    }
  end

  let(:adapter_mock) { Mocks.qbt_adapter(init_args) }

  let(:app) {
    app_args = init_args
    app_args[:adapter] = adapter_mock

    TorrentApp.new(app_args)
  }

  context "calls adapter methods" do

    it "#seed_ratio" do
      expect(adapter_mock).to receive(:seed_ratio)
      app.seed_ratio
    end

    it "#completed_downloads_dir" do
      expect(adapter_mock).to receive(:completed_downloads_dir)
      dir = app.completed_downloads_dir
    end

    it "#app_name" do
      expect(app.app_name).to eq 'qBitTorrent'
    end

    it "#torrent_list" do
      expect(adapter_mock).to receive(:torrent_list).with(any_args)
      app.torrent_list
    end

    it "#get_torrent_job_properties" do
      hash = "AC17F4207E045D532827013C122F6A6300E007E9"

      expect(adapter_mock).to receive(:get_torrent_job_properties).with(hash)
      app.get_torrent_job_properties(hash)
    end

    it "#set_job_properties" do
      props = {}
      props['hash1'] = {"seed_override" => 1, "seed_ratio" => 250}

      expect(adapter_mock).to receive(:set_job_properties).with(props)
      app.set_job_properties(props)
    end

    it "#torrents_removed?" do
      expect(adapter_mock).to receive(:torrents_removed?)
      app.torrents_removed?
    end

    it "#removed_torrents" do
      expect(adapter_mock).to receive(:removed_torrents)
      app.removed_torrents
    end

    it "#torrents" do
      expect(adapter_mock).to receive(:torrents)
      app.torrents
    end

    it "#remove_torrent" do
      hash = "hash1"
      expect(adapter_mock).to receive(:remove_torrent).with(hash)
      app.remove_torrent hash
    end

    it "#get_torrent_seed_ratio" do
      hash = "hash1"
      expect(adapter_mock).to receive(:get_torrent_seed_ratio).with(hash, 0)
      app.get_torrent_seed_ratio hash, 0
    end

    it "#apply_seed_limits" do
      torrents_to_limit = [
        { hash: 'hash1', name: 'torrent1' },
        { hash: 'hash2', name: 'torrent2' },
        { hash: 'hash3', name: 'torrent3' },
      ]
      filters = [
        { url: 'url1', limit: 20 },
        { url: 'url2', limit: 41 },
      ]

      expect(adapter_mock).to receive(:apply_seed_limits).with(torrents_to_limit, filters)
      app.apply_seed_limits torrents_to_limit, filters
    end

    it "#settings" do
      expect(adapter_mock).to receive(:settings)
      app.settings
    end

    it "#rssfilters" do
      expect(adapter_mock).to receive(:rssfilters)
      app.rssfilters
    end

    it "#rssfeeds" do
      expect(adapter_mock).to receive(:rssfeeds)
      app.rssfeeds
    end

    it "#dump_job_properties" do
      expect(adapter_mock).to receive(:dump_job_properties)
      app.dump_job_properties "hash1"
    end
  end
end
