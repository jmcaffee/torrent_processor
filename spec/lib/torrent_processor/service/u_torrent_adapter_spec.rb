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
end
