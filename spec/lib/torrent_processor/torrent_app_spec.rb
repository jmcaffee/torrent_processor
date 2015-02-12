require 'spec_helper'

include TorrentProcessor
include UTorrentHelper

describe TorrentApp do

  let(:app) {
    TorrentApp.new(:cfg => mock_cfg('torrent_app'),
                   :webui => utorrent_stub,
                   :database => mock_db)
  }

  context "#new" do

    it "can be instantiated" do
      obj = TorrentApp.new({})
    end
  end

  context "#seed_ratio" do

    it "returns the global seed_ratio" do
      expect(app.seed_ratio.class).to be Fixnum
    end
  end

  context "#completed_downloads_dir" do

    it "returns the completed downloads directory" do
      dir = app.completed_downloads_dir
      puts "dir: #{dir}"
      expect(dir.empty?).to eq false
    end
  end

  context "#app_name" do

    it "returns the name of the configured app" do
      expect(app.app_name).to eq 'uTorrent'
    end
  end

  context "#torrent_list" do

    it "returns a list of torrents" do
      expect(app.torrent_list).to eq 'uTorrent'
    end
  end
end
