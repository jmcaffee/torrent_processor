require 'rspec/mocks/standalone'

module Mocks

  def self.utorrent
    obj = double('utorrent')
    allow(obj).to receive(:cache)             { 'cache' }
    allow(obj).to receive(:send_get_query)
    allow(obj).to receive(:get_torrent_list)  { TorrentSpecHelper.utorrent_torrent_list_data }
    allow(obj).to receive(:torrents)          { TorrentSpecHelper.utorrent_torrents_data }
    allow(obj).to receive(:rssfeeds)          { TorrentSpecHelper.utorrent_rss_feeds_data }
    allow(obj).to receive(:rssfilters)        { TorrentSpecHelper.utorrent_rss_filters_data }
    allow(obj).to receive(:get_utorrent_settings) { TorrentSpecHelper.ut_settings_data }
    allow(obj).to receive(:settings)          { TorrentSpecHelper.utorrent_settings_data }
    allow(obj).to receive(:get_torrent_job_properties) { TorrentSpecHelper.utorrent_job_properties_data }
    allow(obj).to receive(:torrents_removed?) { false }
    allow(obj).to receive(:remove_torrent)

    obj
  end
end


