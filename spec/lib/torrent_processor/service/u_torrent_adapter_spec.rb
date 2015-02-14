require 'spec_helper'

include TorrentProcessor::Service

describe UTorrentAdapter do

  let(:utorrent_stub) { Mocks.utorrent }
  let(:adapter) {
    UTorrentAdapter.new(:cfg => Mocks.cfg('u_torrent_adapter'),
                        :webui => utorrent_stub,
                        :database => Mocks.db)
  }

  context "#new" do

    it "instantiates a UTorrentAdapter object" do
      obj = UTorrentAdapter.new({})
    end
  end

  context "#app_name" do

    it "returns the name of the torrent app it is adapting" do
      expect(adapter.app_name).to eq 'uTorrent'
    end
  end

  context "#seed_ratio" do

    it "returns the torrent app's configured global seed ratio" do
      expect(adapter.seed_ratio).to eq 0
    end
  end

  context "#completed_downloads_dir" do

    it "returns the torrent app's configured global seed ratio" do
      expect(adapter.completed_downloads_dir).to eq "C:\\XMBC-Apps\\Torrents\\downloads-completed"
    end
  end

  context "#get_torrent_job_properties" do

    it "returns properties of a torrent" do
      hash = "AC17F4207E045D532827013C122F6A6300E007E9"
      expect(adapter.get_torrent_job_properties(hash).key?('props')).to eq true
    end
  end

  context "#set_job_properties" do

    it "sets job properties of a torrent" do
      props = {}
      hash = "AC17F4207E045D532827013C122F6A6300E007E9"
      props[hash] = {"seed_override" => 1, "seed_ratio" => 250}
      expect(utorrent_stub).to receive(:set_job_properties).with(props)

      adapter.set_job_properties(props)
    end
  end

  context "#torrents_removed?" do

    it "determines if any torrents have been removed from the app" do
      expect(utorrent_stub).to receive(:torrents_removed?)

      adapter.torrents_removed?
    end
  end

  context "#removed_torrents" do

    it "returns list of torrents removed since last check" do
      expect(utorrent_stub).to receive(:removed_torrents)

      adapter.removed_torrents
    end
  end

  context "#torrents" do

    it "returns list of cached torrents" do
      expect(utorrent_stub).to receive(:torrents)

      adapter.torrents
    end
  end

  context "#remove_torrent" do

    it "remove a torrent" do
      hash = "AC17F4207E045D532827013C122F6A6300E007E9"
      expect(utorrent_stub).to receive(:remove_torrent).with(hash)

      adapter.remove_torrent hash
    end
  end

  context "#get_torrent_seed_ratio" do

    it "return a torrent's seed ratio" do
      hash = "AC17F4207E045D532827013C122F6A6300E007E9"
      expect(utorrent_stub).to receive(:get_torrent_job_properties).with(hash)

      adapter.get_torrent_seed_ratio hash, 0
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
      adapter.apply_seed_limits torrents_to_limit, filters
    end
  end
end
