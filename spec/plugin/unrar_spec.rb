##############################################################################
# File::    unrar_plugin_spec.rb
# Purpose:: Unrar specification
#
# Author::    Jeff McAffee 01/07/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require_relative '../spec_helper'

include FileUtils
include TorrentProcessor::Plugin

describe Unrar do

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
      obj.stub(:logger) { SimpleLogger }
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
          Unrar.new.execute(controller_stub, torrent_data)
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
          Unrar.new.execute(controller_stub, torrent_data)
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
          Unrar.new.execute(controller_stub, torrent_data)
        end
      end
    end
  end

  context "console commands" do

    let(:unrar_plug)  { Unrar.new }

    let(:console_stub) do
      obj = double("console")
      obj.stub(:logger) { SimpleLogger }
      obj.stub(:cfg)    do
        { :otherprocessing  => torrent_dir,
          :tvprocessing     => torrent_dir,
          :movieprocessing  => torrent_dir
        }
      end
      obj.stub(:database) { db_stub }
      obj
    end

    let(:db_stub) do
      obj = double("database")
      obj.stub(:find_torrent_by_id) { torrent }
      obj
    end

    let(:torrent) do
      {
        :filename => 'multi_rar',
        :filedir  => 'tmp/spec/unrar_plugin_console/completed/multi-rar',
        :label    => 'TV'
      }
    end

  context '#cmd_unrar' do

      let(:torrent_dir)  { 'tmp/spec/unrar_plugin_console/target' }
      let(:torrent_file) { File.join( torrent_dir, 'test_250kb.avi' ) }

      before(:each) do
        blocking_dir_delete(torrent_dir)
        create_downloaded_torrent('spec/data/multi_rar', torrent_dir)
      end

    it 'raises an exception if caller is not provided' do
      expect { unrar_plug.cmd_unrar [] }.to raise_exception
    end

    context 'given a path' do

      it 'unrars an archive' do
        unrar_plug.cmd_unrar([torrent_dir, console_stub])
        expect(File.exists?(torrent_file)).to be true
      end
    end

    context 'given a torrent ID' do

      it 'unrars an archive' do
        unrar_plug.cmd_unrar(['1', console_stub])
      end
    end
  end

  # Private methods
  # Can be deleted at any time.
=begin

  context '#text_to_id' do

    it 'returns a numeric ID from a string' do
      expect(unrar_plug.text_to_id('10')).to eq 10
    end

    it 'returns -1 if string is not an integer' do
      expect(unrar_plug.text_to_id('1a')).to eq -1
    end
  end
=end

  end # context "console commands"
end
