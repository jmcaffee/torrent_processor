require 'torrent_spec_helper'

module UTorrentHelper

  def utorrent_stub
    obj = double('utorrent')
    obj.stub(:cache)                      { 'cache' }
    obj.stub(:get_torrent_list)           { TorrentSpecHelper.utorrent_torrent_list_data() }
    obj.stub(:torrents)                   { TorrentSpecHelper.utorrent_torrents_data() }

    obj
  end
end # module UTorrentHelper
