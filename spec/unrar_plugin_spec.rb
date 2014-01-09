##############################################################################
# File::    unrar_plugin_spec.rb
# Purpose:: UnrarPlugin specification
#
# Author::    Jeff McAffee 01/07/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require_relative './spec_helper'

include FileUtils
include TorrentProcessor::ProcessorPlugin

describe UnrarPlugin do

  context '#execute' do

    before(:each) do
      blocking_dir_delete test_root_dir
      mkdir_p target_root_dir
      src = File.join(data_dir, test_torrent_dir)
      cp_r(src, target_root_dir) if !File.exists?(File.join(target_root_dir, test_torrent_dir))
      mv(File.join(target_root_dir, test_torrent_dir), File.join(target_root_dir, test_torrent_name))

      TorrentProcessor.configure do |config|
        config.utorrent.dir_completed_download = completed_downloads
      end

      blocking_file_delete(File.join(target_dir, test_torrent))
    end

    let(:completed_downloads) { File.join(test_root_dir, 'completed_downloads') }
    let(:target_root_dir)     { File.join(test_root_dir, 'target') }
    let(:test_root_dir)       { 'tmp/spec/unrar_plugin' }

    let(:controller_stub) do
      obj = double("controller")
      obj.stub(:log) { SimpleLogger }
      obj.stub(:cfg) do
        {
          :otherprocessing  => target_root_dir,
          :tvprocessing     => target_root_dir,
          :movieprocessing  => target_root_dir
        }
      end
      obj
    end

    context 'given a .rar archive' do

      context 'given media file(s) in nested dir' do

        let(:data_dir)          { 'spec/data' }
        let(:test_torrent_dir)  { 'multi_rar' }
        let(:test_torrent_name) { 'test_250kb' }
        let(:test_torrent)      { test_torrent_name + '.avi' }
        let(:target_dir)        { File.join(target_root_dir, test_torrent_name) }

        let(:torrent_data) do
          {
            :filename => test_torrent_name,
            :filedir  => File.join(completed_downloads, test_torrent_name),
            :label    => 'TV'
          }
        end

        it "extracts a file from a rar archive in the destination directory" do
          UnrarPlugin.new.execute(controller_stub, torrent_data)
          expect(File.exists?(File.join(target_dir, test_torrent))).to be true
        end
      end
    end

    context 'given a NON .rar archive' do

      context 'given media file(s) in nested dir' do

        let(:data_dir)          { 'spec/data' }
        let(:test_torrent_dir)  { 'rar_source' }
        let(:test_torrent_name) { 'test_250kb' }
        let(:test_torrent)      { test_torrent_name + '.avi' }
        let(:target_dir)        { File.join(target_root_dir, test_torrent_name) }

        let(:torrent_data) do
          {
            :filename => test_torrent,
            :filedir  => File.join(completed_downloads, test_torrent_name),
            :label    => 'TV'
          }
        end

        it "skips (does not fail) directories with no .rar archives" do
          UnrarPlugin.new.execute(controller_stub, torrent_data)
        end
      end

      context 'given media file(s) NOT in nested dir' do

        let(:data_dir)          { 'spec/data' }
        let(:test_torrent_dir)  { 'rar_source' }
        let(:test_torrent_name) { 'test_250kb' }
        let(:test_torrent)      { test_torrent_name + '.avi' }
        let(:target_dir)        { File.join(target_root_dir, test_torrent_name) }

        let(:torrent_data) do
          {
            :filename => test_torrent,
            :filedir  => completed_downloads,
            :label    => 'TV'
          }
        end

        it "skips (does not fail) torrents that are not in a subdirectory" do
          UnrarPlugin.new.execute(controller_stub, torrent_data)
        end
      end
    end
  end
end
