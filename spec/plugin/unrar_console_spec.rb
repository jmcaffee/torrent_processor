##############################################################################
# File::    unrar_console_spec.rb
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
      let(:test_root_dir)       { spec_tmp_dir('unrar_plugin_console/') }
      let(:torrent_dir)         { spec_tmp_dir('unrar_plugin_console/target/') }
      let(:torrent_file)        { File.join( torrent_dir, torrent[:filename], 'test_250kb.avi' ) }
      let(:cmd)                 { '.unrar' }

      before(:each) do
        if !torrent_dir.nil? &&
          blocking_dir_delete(torrent_dir)
        end

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
      let(:create_multi_rar) { create_rar_file(File.join(torrent_dir, torrent[:filename])) }

      it 'unrars an archive' do
        create_multi_rar

        unrar_plug.cmd_unrar(cmd_args)

        # size? returns nil if file doesn't exist or file size is 0:
        expect((!File.size?(torrent_file).nil?)).to be true
      end

      context 'new style archive' do

        it 'deletes rar files on successful extraction' do
          create_multi_rar

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

      # In these scenarios, the rar file(s) the ID references are in the
      # 'completed' directory.
      #
      # Unrar will need to 'unrar' the files AT the target (sickbeard incoming media)
      # directory location.

      let(:cmd) { ".unrar 1" }

      # Simulate a rar torrent that has been copied to the SickBeard pool
      let(:torrent_file) { File.join(spec_tmp_dir('unrar_plugin_console/target/multi_rar'), 'test_250kb.avi' ) }
      let(:torrent_dir)  { spec_tmp_dir('unrar_plugin_console/target') }
      let(:create_multi_rar) { create_rar_file(File.join(torrent_dir, torrent[:filename])) }

      it 'unrars an archive in target dir' do
        create_multi_rar

        unrar_plug.cmd_unrar(cmd_args)

        expect(File.exists?(torrent_file)).to be true
      end

      context 'new style archive' do

        it 'deletes rar files on successful extraction' do
          create_multi_rar

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

        # Simulate a rar torrent that has been copied to the SickBeard pool
        let(:torrent_file) { File.join(spec_tmp_dir('unrar_plugin_console/target/old_style_rar'), 'test_250kb.avi' ) }
        let(:torrent_dir)  { spec_tmp_dir('unrar_plugin_console/target') }
        let(:create_multi_rar) { create_rar_file(File.join(torrent_dir, torrent[:filename])) }

        it 'deletes rar files on successful extraction' do
          create_multi_rar

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
