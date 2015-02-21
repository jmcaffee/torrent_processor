# encoding: utf-8
require 'spec_helper'

include TorrentProcessor::Service::QBitTorrent

describe TorrentData do

  let(:torrent) do
      {
          "dlspeed"=>"3.1 MiB/s",
          "eta"=>"9m",
          "hash"=>"156b69b8643bd11849a5d8f2122e13fbb61bd041",
          "name"=>"slackware64-14.1-iso",
          "num_leechs"=>"1 (14)",
          "num_seeds"=>"97 (270)",
          "priority"=>"*",
          "progress"=>0.172291,
          "ratio"=>"0.0",
          "size"=>"2.2 GiB",
          "state"=>"downloading",
          "upspeed"=>"0 B/s",
          "comment"=>"Visit us: https://eztv.ch/ - Bitcoin: 1EZTVaGQ6UsjYJ9fwqGnd45oZ6HGT7WKZd",
          "creation_date"=>"Friday, February 6, 2015 8:01:22 PM MST",
          "dl_limit"=>"∞",
          "nb_connections"=>"0 (100 max)",
          "piece_size"=>"512.0 KiB",
          "save_path"=>"/home/jeff/Downloads/",
          #"share_ratio"=>"0.0",
          "share_ratio"=>"∞",
          "time_elapsed"=>"< 1m",
          "total_downloaded"=>"646.8 KiB (657.8 KiB this session)",
          #"total_uploaded"=>"0 B (0 B this session)",
          "total_uploaded"=>"800 MiB (0 B this session)",
          "total_wasted"=>"428 B",
          "up_limit"=>"∞"
      }
  end
  let(:sut) { TorrentData.new(torrent) }

  context "#new" do

    it "can be instantiated" do
      obj = TorrentData.new(torrent)
    end
  end

  context "#normalize_percents" do

    it "converts percentage of progress to integer" do
      sut.normalize_percents
      expect(sut.name).to eq 'slackware64-14.1-iso'
      expect(sut.percent_progress).to eq 172
    end

    it "converts ratio percentage to integer" do
      sut.normalize_percents
      expect(sut.uploaded).to eq 838_860_800
      expect(sut.downloaded).to eq 662_323
      expect(sut.ratio).to eq (1000 * (sut.uploaded / sut.downloaded))
    end
  end
end
