require 'rspec/mocks/standalone'
require 'qbt_client'

module Mocks

  def self.qbtorrent
    #obj = double('qbt_client/webui')
    obj = instance_double('QbtClient::WebUI')
    allow(obj).to receive(:torrent_list)      { TorrentSpecHelper.qbt_torrent_list_data }
    allow(obj).to receive(:properties)        { TorrentSpecHelper.qbt_torrent_properties_data }
    allow(obj).to receive(:trackers)          { TorrentSpecHelper.qbt_torrent_tracker_data }
    allow(obj).to receive(:add_trackers)      { }
    allow(obj).to receive(:contents)          { TorrentSpecHelper.qbt_torrent_contents_data }
    allow(obj).to receive(:transfer_info)     { TorrentSpecHelper.qbt_app_transfer_data }
    allow(obj).to receive(:preferences)       { TorrentSpecHelper.qbt_settings_data }
    allow(obj).to receive(:set_preferences)   { }
    allow(obj).to receive(:pause)             { }
    allow(obj).to receive(:pause_all)         { }
    allow(obj).to receive(:resume)            { }
    allow(obj).to receive(:resume_all)        { }
    allow(obj).to receive(:download)          { }
    allow(obj).to receive(:delete_torrent_and_data) { }
    allow(obj).to receive(:delete)            { }
    allow(obj).to receive(:recheck)           { }
    allow(obj).to receive(:increase_priority) { }
    allow(obj).to receive(:decrease_priority) { }
    allow(obj).to receive(:maximize_priority) { }
    allow(obj).to receive(:minimize_priority) { }
    allow(obj).to receive(:set_file_priority) { }
    allow(obj).to receive(:global_download_limit)   { 0 }
    allow(obj).to receive(:set_global_download_limit) { }
    allow(obj).to receive(:global_upload_limit)     { 0 }
    allow(obj).to receive(:set_global_upload_limit) { }
    allow(obj).to receive(:download_limit)    { 0 }
    allow(obj).to receive(:set_download_limit){ }
    allow(obj).to receive(:upload_limit)      { 0 }
    allow(obj).to receive(:set_upload_limit)  { }

    obj
  end

  def self.qbt_adapter init_args = {}
    obj = TorrentProcessor::Service::QBitTorrentAdapter.new(init_args)
    #obj = instance_double('TorrentProcessor::Service::QBitTorrentAdapter')

    #allow(TorrentProcessor::Service::QBitTorrentAdapter).to receive(:seed_ratio) { 0 }
    allow(obj).to receive(:seed_ratio) { 0 }
    #allow_any_instance_of(TorrentProcessor::Service::QBitTorrentAdapter).to receive(:initialize).and_return obj
    obj
  end
end


