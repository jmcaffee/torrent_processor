require 'rspec/mocks/standalone'

module Mocks

  def self.utorrent
    obj = double('utorrent')
    obj.stub(:cache)            { 'cache' }
    obj.stub(:get_torrent_list) { TorrentSpecHelper.utorrent_torrent_list_data }
    obj.stub(:torrents)         { TorrentSpecHelper.utorrent_torrents_data }
    obj.stub(:rssfeeds)         { TorrentSpecHelper.utorrent_rss_feeds_data }
    obj.stub(:rssfilters)       { TorrentSpecHelper.utorrent_rss_filters_data }
    obj.stub(:get_utorrent_settings) { TorrentSpecHelper.ut_settings_data }

    obj
  end
end


