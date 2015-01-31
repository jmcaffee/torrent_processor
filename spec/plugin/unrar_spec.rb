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
        config.tv_processing    = target_root_dir
        config.movie_processing = target_root_dir
        config.other_processing = target_root_dir

        config.utorrent.dir_completed_download = completed_downloads
      end

      blocking_file_delete(File.join(target_dir, test_torrent))
    end

    let(:completed_downloads) { File.join(test_root_dir, 'completed_downloads') }
    let(:target_root_dir)     { File.join(test_root_dir, 'target') }
    let(:test_root_dir)       { 'tmp/spec/unrar_plugin' }
    let(:logger)              { NullLogger }

    let(:context_args) { { :logger => logger } }

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
          Unrar.new.execute(context_args, torrent_data)
          expect(File.exists?(File.join(target_dir, test_torrent))).to be true
        end

        it 'deletes rar files on successful extraction' do
          Unrar.new.execute(context_args, torrent_data)

          expect(File.exists?(File.join(target_dir, test_torrent))).to be true
          rars = Dir[File.join(target_dir,'**/*.rar')]
          expect(rars.count).to be 0
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
          Unrar.new.execute(context_args, torrent_data)
        end
      end
    end
  end

  context "console commands" do

    let(:unrar_plug)  { Unrar.new }
    let(:cmd_args) do
        {
          :cmd      => cmd,
          :logger   => logger,
          :utorrent => utorrent_stub,
          :database => db_stub,
        }
    end

    let(:logger) { NullLogger }
    #let(:logger)  { SimpleLogger }

    let(:db_stub) do
      obj = double("database")
      obj.stub(:find_torrent_by_id) { torrent }
      obj
    end

    let(:utorrent_stub) do
      obj = double("utorrent")
      obj
    end

    let(:torrent) do
      {
        :filename => 'multi_rar',
        :filedir  => 'tmp/spec/unrar_plugin_console/completed/multi_rar',
        :label    => 'TV'
      }
    end

  context '#cmd_unrar' do

      let(:target_root_dir)     { File.join(test_root_dir, 'target') }
      let(:test_root_dir)       { 'tmp/spec/unrar_plugin_console' }
      let(:torrent_dir)  { 'tmp/spec/unrar_plugin_console/target' }
      let(:torrent_file) { File.join( torrent_dir, torrent[:filename], 'test_250kb.avi' ) }
      let(:cmd) { '.unrar' }

      before(:each) do
        blocking_dir_delete(torrent_dir)
        create_downloaded_torrent('spec/data/multi_rar', torrent_dir)

        TorrentProcessor.configure do |config|
          config.tv_processing    = target_root_dir
          config.movie_processing = target_root_dir
          config.other_processing = target_root_dir

          config.utorrent.dir_completed_download = File.join(test_root_dir, 'completed')
        end
      end

    it 'raises an exception if caller is not provided' do
      expect { unrar_plug.cmd_unrar {} }.to raise_exception
    end

    context 'given a path' do

      let(:cmd) { ".unrar #{File.join(torrent_dir, torrent[:filename])}" }

      it 'unrars an archive' do
        unrar_plug.cmd_unrar(cmd_args)

        expect(File.exists?(torrent_file)).to be true
      end

      context 'new style archive' do

        it 'deletes rar files on successful extraction' do
          unrar_plug.cmd_unrar(cmd_args)

          expect(File.exists?(torrent_file)).to be true
          rars = Dir[File.join(torrent_dir,'**/*.rar')]
          expect(rars.count).to be 0
        end
      end # new style

      context 'old style archive' do

        before(:each) do
          blocking_dir_delete(torrent_dir)
          create_downloaded_torrent('spec/data/old_style_rar', torrent_dir)
        end

        let(:torrent) do
          {
            :filename => 'old_style_rar',
            :filedir  => 'tmp/spec/unrar_plugin_console/completed/old_style_rar',
            :label    => 'TV'
          }
        end

        it 'deletes rar files on successful extraction' do
          unrar_plug.cmd_unrar(cmd_args)

          expect(File.exists?(torrent_file)).to be true
          rars = Dir[File.join(torrent_dir,'**/*.r??')]
          expect(rars.count).to be 0
        end
      end # old style

      context 'handles windows file separators' do

        before(:each) do
          blocking_dir_delete(torrent_dir)
          create_downloaded_torrent('spec/data/multi_rar', torrent_dir)
        end

        let(:torrent_dir)  { 'tmp\\spec\\unrar_plugin_console\\target' }

        it 'deletes rar files on successful extraction' do
          unrar_plug.cmd_unrar(cmd_args)

          expect(File.exists?(torrent_file)).to be true
          rars = Dir[File.join(torrent_dir.gsub('\\','/'),'**/*.r??')]
          expect(rars.count).to be 0
        end
      end # old style
    end # given a path

    context 'given a torrent ID' do

      let(:cmd) { ".unrar 1" }

      it 'unrars an archive' do
        unrar_plug.cmd_unrar(cmd_args)

        expect(File.exists?(torrent_file)).to be true
      end

      context 'new style archive' do

        it 'deletes rar files on successful extraction' do
          unrar_plug.cmd_unrar(cmd_args)

          expect(File.exists?(torrent_file)).to be true
          rars = Dir[File.join(torrent_dir,'**/*.rar')]
          expect(rars.count).to be 0
        end
      end # new style

      context 'old style archive' do

        before(:each) do
          blocking_dir_delete(torrent_dir)
          create_downloaded_torrent('spec/data/old_style_rar', torrent_dir)
        end

        let(:torrent) do
          {
            :filename => 'old_style_rar',
            :filedir  => 'tmp/spec/unrar_plugin_console/completed/old_style_rar',
            :label    => 'TV'
          }
        end

        it 'deletes rar files on successful extraction' do
          unrar_plug.cmd_unrar(cmd_args)

          expect(File.exists?(torrent_file)).to be true
          rars = Dir[File.join(torrent_dir,'**/*.r??')]
          expect(rars.count).to be 0
        end
      end # old style
    end

    context 'no argument provided' do

      let(:cmd) { '.unrar' }
      let(:logger) { CaptureLogger }

      it 'returns true indicating the command was handled' do
        expect(unrar_plug.cmd_unrar(cmd_args)).to be_truthy
      end

      it 'logs an error message' do
        unrar_plug.cmd_unrar(cmd_args)

        expect(CaptureLogger.messages.include?('Error: path to directory or torrent ID expected')).to be_truthy
      end

      it 'displays help message' do
        unrar_plug.cmd_unrar(cmd_args)

        expect(CaptureLogger.messages.include?('.unrar [FILE_PATH or TORRENT_ID]')).to be_truthy
      end
    end # no arg provided
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
