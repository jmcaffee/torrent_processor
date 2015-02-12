require 'spec_helper'

include TorrentProcessor::Service

describe UTorrentAdapter do

  let(:adapter) {
    UTorrentAdapter.new(:cfg => Mocks.cfg('u_torrent_adapter'),
                        :webui => Mocks.utorrent,
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
end
