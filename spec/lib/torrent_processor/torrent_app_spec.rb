require 'spec_helper'

include TorrentProcessor

describe TorrentApp do

  let(:utorrent_stub) { Mocks.utorrent }

  let(:app) {
    TorrentApp.new(:cfg         => Mocks.cfg('torrent_app'),
                   :webui       => utorrent_stub,
                   :webui_type  => :utorrent,
                   :database    => Mocks.db)
  }

  context "#new" do

    it "can be instantiated" do
      obj = TorrentApp.new({})
    end

    it "default webui type is :utorrent" do
      obj = TorrentApp.new({})
      expect(obj.webui_type).to eq :utorrent
    end

    it ":webui_type must be provided if passing :webui" do
      expect{ TorrentApp.new(:webui => utorrent_stub) }.to raise_exception
    end

    it "unrecognized :webui_type raises an exception" do
      obj = TorrentApp.new(:webui_type => :unknown)
      expect{ obj.seed_ratio }.to raise_exception("Unknown webui_type: :unknown")
    end
  end

  context "#seed_ratio" do

    it "returns the global seed_ratio" do
      expect(utorrent_stub).to receive(:get_utorrent_settings)
      app.seed_ratio.class
    end
  end

  context "#completed_downloads_dir" do

    it "returns the completed downloads directory" do
      expect(utorrent_stub).to receive(:get_utorrent_settings)
      dir = app.completed_downloads_dir
    end
  end

  context "#app_name" do

    it "returns the name of the configured app" do
      expect(app.app_name).to eq 'uTorrent'
    end
  end

  context "#torrent_list" do

    it "returns a list of torrents" do
      expect(utorrent_stub).to receive(:get_torrent_list).with(any_args)
      app.torrent_list
    end
  end

  context "#get_torrent_job_properties" do

    it "returns properties of a torrent" do
      hash = "AC17F4207E045D532827013C122F6A6300E007E9"

      expect(utorrent_stub).to receive(:get_torrent_job_properties).with(hash)
      app.get_torrent_job_properties(hash)
    end
  end

  context "#set_job_properties" do

    it "sets job properties of a torrent" do
      props = {}
      hash = "AC17F4207E045D532827013C122F6A6300E007E9"
      props[hash] = {"seed_override" => 1, "seed_ratio" => 250}

      expect(utorrent_stub).to receive(:set_job_properties).with(props)
      app.set_job_properties(props)
    end
  end

  context "#torrents_removed?" do

    it "determine if any torrents have been removed from the app" do
      expect(utorrent_stub).to receive(:torrents_removed?)
      app.torrents_removed?
    end
  end

  context "#removed_torrents" do

    it "return list of removed torrents" do
      expect(utorrent_stub).to receive(:removed_torrents)
      app.removed_torrents
    end
  end

  context "#torrents" do

    it "return list of cached torrents" do
      expect(utorrent_stub).to receive(:torrents)
      app.torrents
    end
  end

  context "#remove_torrent" do

    it "remove a torrent" do
      hash = "AC17F4207E045D532827013C122F6A6300E007E9"
      expect(utorrent_stub).to receive(:remove_torrent).with(hash)
      app.remove_torrent hash
    end
  end

  context "#get_torrent_seed_ratio" do

    it "return a torrent's seed ratio" do
      hash = "AC17F4207E045D532827013C122F6A6300E007E9"
      expect(utorrent_stub).to receive(:get_torrent_job_properties).with(hash)
      app.get_torrent_seed_ratio hash, 0
    end
  end

  context "#apply_seed_limits" do

    it "apply tracker filter seed limits to a collection of torrents" do
      torrents_to_limit = [
        { hash: 'hash1', name: 'torrent1' },
        { hash: 'hash2', name: 'torrent2' },
        { hash: 'hash3', name: 'torrent3' },
      ]
      filters = [
        { url: 'url1', limit: 20 },
        { url: 'url2', limit: 41 },
      ]

      expect(utorrent_stub).to receive(:get_torrent_job_properties).with('hash1')
      expect(utorrent_stub).to receive(:get_torrent_job_properties).with('hash2')
      expect(utorrent_stub).to receive(:get_torrent_job_properties).with('hash3')
      app.apply_seed_limits torrents_to_limit, filters
    end
  end

  context "#settings" do

    it "return torrent app settings" do
      expect(utorrent_stub).to receive(:get_utorrent_settings)
      app.settings
    end
  end

  context "#rssfilters" do

    it "return rss filters from torrent app" do
      expect(utorrent_stub).to receive(:rssfilters)
      app.rssfilters
    end
  end

  context "#rssfeeds" do

    it "return rss feeds from torrent app" do
      expect(utorrent_stub).to receive(:rssfeeds)
      app.rssfeeds
    end
  end
end
