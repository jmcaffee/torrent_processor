require 'spec_helper'

include TorrentProcessor::Service

describe QBitTorrentAdapter do

  let(:qbt_stub) { Mocks.qbtorrent }
  let(:adapter) {
    QBitTorrentAdapter.new(:cfg => Mocks.cfg('q_bit_torrent_adapter'),
                        :webui => qbt_stub,
                        :database => Mocks.db)
  }

  context "#new" do

    it "instantiates a QBitTorrentAdapter object" do
      obj = QBitTorrentAdapter.new({})
    end
  end

  context "#app_name" do

    it "returns the name of the torrent app it is adapting" do
      expect(adapter.app_name).to eq 'qBitTorrent'
    end
  end

  context "#seed_ratio" do

    it "returns the torrent app's configured global seed ratio" do
      expect(adapter.seed_ratio).to eq 0
    end
  end

  context "#completed_downloads_dir" do

    it "returns the torrent app's completed downloads dir" do
      expect(adapter.completed_downloads_dir).to eq "/home/jeff/Downloads"
    end
  end

  context "#get_torrent_job_properties" do

    it "returns properties of a torrent" do
      hash = "AC17F4207E045D532827013C122F6A6300E007E9"
      expect(adapter.get_torrent_job_properties(hash).key?('comment')).to eq true
    end
  end

  context "#set_job_properties" do

    it "is not supported on WebUI and raises exception" do
      #props = {}
      #hash = "AC17F4207E045D532827013C122F6A6300E007E9"
      #props[hash] = {"seed_override" => 1, "seed_ratio" => 250}
      #expect(qbt_stub).to receive(:set_job_properties).with(props)

      expect { adapter.set_job_properties(props) }.to raise_exception
    end
  end

  context "#torrents_removed?" do

    it "returns true if torrents have been removed from the app" do
      # Create a file cache file
      cache_data = ['hash1', 'hash2', 'hash3']
      yml_path = File.join(spec_tmp_dir('q_bit_torrent_adapter'), 'qbtcache.yml')
      File.open(yml_path, 'w+') { |f| f.write(YAML.dump(cache_data)) }

      current_torrent_data = [
          {
              "hash"=>"hash1",
              "name"=>"slackware64-14.1-iso",
          },
          {
            "hash"=>"hash2",
            "name"=>"Grimm.S04E12.720p.HDTV.X264-DIMENSION.mkv",
          }
        ]

      # Return specific data from the torrent_list method:
      expect(qbt_stub).to receive(:torrent_list)
        .and_return(current_torrent_data)

      expect(adapter.torrents_removed?).to eq true
    end

    it "returns false if torrents have not been removed from the app" do
      # Create a file cache file
      cache_data = ['hash1', 'hash2']
      yml_path = File.join(spec_tmp_dir('q_bit_torrent_adapter'), 'qbtcache.yml')
      File.open(yml_path, 'w+') { |f| f.write(YAML.dump(cache_data)) }

      current_torrent_data = [
          {
              "hash"=>"hash1",
              "name"=>"slackware64-14.1-iso",
          },
          {
            "hash"=>"hash2",
            "name"=>"Grimm.S04E12.720p.HDTV.X264-DIMENSION.mkv",
          }
        ]

      # Return specific data from the torrent_list method:
      expect(qbt_stub).to receive(:torrent_list)
        .and_return(current_torrent_data)

      expect(adapter.torrents_removed?).to eq false
    end
  end

  context "#removed_torrents" do

    it "returns list of torrents removed since last check" do
      # Create a file cache file
      cache_data = ['hash1', 'hash2', 'hash3']
      yml_path = File.join(spec_tmp_dir('q_bit_torrent_adapter'), 'qbtcache.yml')
      File.open(yml_path, 'w+') { |f| f.write(YAML.dump(cache_data)) }

      current_torrent_data = [
          {
              "hash"=>"hash1",
              "name"=>"slackware64-14.1-iso",
          },
          {
            "hash"=>"hash2",
            "name"=>"Grimm.S04E12.720p.HDTV.X264-DIMENSION.mkv",
          }
        ]

      # Return specific data from the torrent_list method:
      expect(qbt_stub).to receive(:torrent_list)
        .and_return(current_torrent_data)

      # Verify the method returns the hash that is missing.
      expect(adapter.removed_torrents).to include('hash3') #.include?('hash3')).to eq true
    end
  end

  context "#torrents" do

    it "returns list of cached torrents" do
      expect(qbt_stub).to receive(:torrent_list)

      adapter.torrents
    end
  end

  context "#remove_torrent" do

    it "remove a torrent" do
      hash = "AC17F4207E045D532827013C122F6A6300E007E9"
      expect(qbt_stub).to receive(:delete_torrent_and_data).with(hash)

      adapter.remove_torrent hash
    end
  end

  context "#get_torrent_seed_ratio" do

    it "return a torrent's seed ratio" do
      hash = "AC17F4207E045D532827013C122F6A6300E007E9"
      expect(qbt_stub).to receive(:properties).with(hash)

      adapter.get_torrent_seed_ratio hash, 0
    end
  end

  context "#apply_seed_limits" do

    it "apply tracker filter seed limits to a collection of torrents" do
      pending('Not supported')
      torrents_to_limit = [
        { hash: 'hash1', name: 'torrent1' },
        { hash: 'hash2', name: 'torrent2' },
        { hash: 'hash3', name: 'torrent3' },
      ]
      filters = [
        { url: 'url1', limit: 20 },
        { url: 'url2', limit: 41 },
      ]

      expect(qbt_stub).to receive(:properties).with('hash1')
      expect(qbt_stub).to receive(:properties).with('hash2')
      expect(qbt_stub).to receive(:properties).with('hash3')
      adapter.apply_seed_limits torrents_to_limit, filters
    end
  end

  context "#settings" do

    it "returns qBitTorrent settings" do
      expect(qbt_stub).to receive(:preferences)

      adapter.settings
    end
  end

  context "#rssfilters" do

    it "returns qBitTorrent rss filters" do
      #expect(qbt_stub).to receive(:rssfilters)

      expect(adapter.rssfilters).to be_empty
    end
  end

  context "#rssfeeds" do

    it "returns qBitTorrent rss feeds" do
      #expect(qbt_stub).to receive(:rssfeeds)

      expect(adapter.rssfeeds).to be_empty
    end
  end
end
