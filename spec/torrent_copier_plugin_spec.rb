##############################################################################
# File::    torrent_copier_plugin_spec.rb
# Purpose:: TorrentCopierPlugin specification
# 
# Author::    Jeff McAffee 01/06/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require_relative './spec_helper'

include TorrentProcessor::ProcessorPlugin
include FileUtils

describe TorrentCopierPlugin do

  context '#execute' do

    before(:each) do
      blocking_dir_delete test_root_dir
      mkdir_p completed_downloads
      src = File.join(data_dir, test_torrent)
      if File.directory?(src)
        cp_r(src, completed_downloads) if !File.exists?(File.join(completed_downloads, test_torrent))
      else
        cp(src, completed_downloads) if !File.exists?(File.join(completed_downloads, test_torrent))
      end

      TorrentProcessor.configure do |config|
        config.utorrent.dir_completed_download = completed_downloads
      end
      blocking_file_delete(File.join(completed_downloads, 'robocopy.log'))
      blocking_file_delete(File.join(target_dir, test_torrent))
    end

    let(:completed_downloads) { File.join(test_root_dir, 'completed_downloads') }
    let(:target_dir)          { File.join(test_root_dir, 'target') }
    let(:test_root_dir)       { 'tmp/spec/torrent_copier_plugin' }
    let(:data_dir)            { 'spec/data/rar_source' }
    let(:test_torrent)        { 'test_250kb.avi' }
    let(:ctx)           { double("controller", { :log => SimpleLogger, :cfg => { :otherprocessing => target_dir, :tvprocessing => target_dir, :movieprocessing => target_dir } }) }
    let(:torrent_data)  { { :filename => test_torrent, :filedir => completed_downloads, :label => 'TV' } }

    context 'given a single media file' do

      it "copies a file to the configured destination directory" do
        TorrentCopierPlugin.new.execute(ctx, torrent_data)
        expect(File.exists?(File.join(target_dir, test_torrent))).to be true
      end
    end

    context 'given media file(s) in nested dir' do

      let(:data_dir)            { 'spec/data' }
      let(:test_torrent)        { 'multi_rar' }
      let(:torrent_data)  { { :filename => test_torrent, :filedir => File.join(completed_downloads, test_torrent), :label => 'TV' } }

      it "copies a directory to the configured destination directory" do
        TorrentCopierPlugin.new.execute(ctx, torrent_data)
        expect(File.exists?(File.join(target_dir, test_torrent))).to be true
        expect(File.exists?(File.join(target_dir, test_torrent, 'test_250kb.part06.rar'))).to be true
      end
    end
  end
end

