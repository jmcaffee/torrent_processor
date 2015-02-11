
module UTorrentHelper

  def utorrent_stub
    obj = double('utorrent')
    obj.stub(:cache)            { 'cache' }
    obj.stub(:get_torrent_list) { TorrentSpecHelper.utorrent_torrent_list_data() }
    obj.stub(:torrents)         { TorrentSpecHelper.utorrent_torrents_data() }
    obj.stub(:rssfeeds)         { TorrentSpecHelper.utorrent_rss_feeds_data() }
    obj.stub(:rssfilters)       { TorrentSpecHelper.utorrent_rss_filters_data() }

    obj
  end
end # module UTorrentHelper
