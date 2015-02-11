##############################################################################
# File::    processor_spec.rb
# Purpose:: Specification for Processor class
# 
# Author::    Jeff McAffee 01/08/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'spec_helper'
require 'torrent_processor/plugin/movie_mover'

include TorrentProcessor

describe Processor do

  before(:all) do
    TorrentProcessor.configure
  end

  subject(:processor) do
    obj = Processor.new(args)
    obj
  end

  let(:args) do
    {
      #:logger   => SimpleLogger,
      :cfg      => cfg_stub,
      :moviedb  => moviedb_stub,
      :utorrent => utorrent_stub,
      :database => db_stub,
    }
  end

  let(:cfg_stub) do
    obj = double('configuration')
    obj.stub(:ip)                 { '127.0.0.1' }
    obj.stub(:port)               { '8080' }
    obj.stub(:user)               { 'xbmc' }
    obj.stub(:pass)               { 's3cr3t' }
    obj.stub(:filters)            { { 'test' => '0' } }
    obj.stub(:movie_processing)   { 'tmp/spec/procerror/movies' }
    obj.stub(:tmdb) { cfg_tmdb_stub }
    obj
  end

  let(:cfg_tmdb_stub) do
    obj = double('tmdb_configuration')
    obj.stub(:target_movies_path)   { 'tmp/spec/processor/movies-target' }
    obj.stub(:can_copy_start_time)  { '00:00' }
    obj.stub(:can_copy_stop_time)   {'23:59'  }
    obj
  end

  let(:moviedb_stub) do
    obj = double('moviedb')
    obj
  end

  let(:utorrent_stub) do
    obj = double('utorrent')
    obj.stub(:startSession) { true }
    obj.stub(:get_utorrent_settings) do
      [
        ['seed_ratio', 1, 0],
        ['dir_completed_download', 1, 'completed-dir']
      ]
    end
    obj.stub(:get_torrent_list) { [] }
    obj.stub(:cache) { 'cache' }
    obj.stub(:torrents) { { 'hash1' => 'torrent data' } }
    obj.stub(:torrents_removed?) { false }
    obj
  end

  let(:db_stub) do
    obj = double('database')
    obj.stub(:read_cache) { 'cache' }
    obj.stub(:update_cache) { true }
    obj.stub(:update_torrents) { true }
    obj.stub(:update_torrent_state) { true }

    obj.stub(:execute) do |q|
      if q == 'SELECT hash, name, folder, label FROM torrents WHERE tp_state = "processing";'
        res = [
          #[ 'hash0', 'testTorrent0', 'download-dir', 'TV' ],
          [ 'hash1', 'testTorrent1', 'download-dir', 'TV' ]
        ]
      else
        res = []
      end
      res
    end

    obj
  end

  describe '#new' do

    it 'instantiates a processor object' do
      Processor.new(
        #:logger   => SimpleLogger,
        :cfg      => cfg_stub,
        :moviedb  => moviedb_stub,
        :utorrent => utorrent_stub,
        :database => db_stub )
    end
  end

  describe '#process' do

    context 'plugin raises exception' do

      it 'aborts processing the torrent' do
        TorrentProcessor::Plugin::TorrentCopier.any_instance.should_receive(:execute) {
          raise TorrentProcessor::Plugin::PluginError, 'an exception'
        }

        processor.process
      end
    end # context plugin raises exception

    context 'torrent state is NULL' do

      let(:utorrent_stub) do
        obj = double('utorrent')
        obj.stub(:startSession) { true }
        obj.stub(:get_utorrent_settings) do
          [
            ['seed_ratio', 0, 0],
            ['dir_completed_download', 1, 'completed-dir']
          ]
        end
        obj.stub(:get_torrent_list) { [] }
        obj.stub(:cache) { 'cache' }
        obj.stub(:torrents) { [] }
        obj.stub(:torrents_removed?) { false }
        obj.stub(:get_torrent_job_properties) do
          {
            'props' =>
            [
              {
                'seed_override' => 0,
                'seed_ratio' => 100,
                'trackers' => 'my.test.tracker'
              }
            ]
          }
        end
        obj
      end

      context 'download in progress' do

        let(:db_stub) do
          obj = double('database')
          obj.stub(:read_cache) { 'cache' }
          obj.stub(:update_cache) { true }
          obj.stub(:update_torrents) { true }
          #obj.stub(:update_torrent_state) { true }

          obj.stub(:execute) do |q|
            if q == 'SELECT hash, percent_progress, name FROM torrents WHERE tp_state IS NULL;'
              res = [
                #[ 'hash0', 'testTorrent0', 'download-dir', 'TV' ],
                [ 'hash1', 10, 'testTorrent1' ]
              ]
            else
              res = []
            end
            res
          end

          obj
        end

        it 'applies seed limit filters to new torrents and changes state to downloading' do
          utorrent_stub.should_receive(:set_job_properties).with(
            {
              'hash1' =>
              {
                'seed_override' => 1,
                'seed_ratio' => 0
              }
            }
          )
          db_stub.should_receive(:update_torrent_state).with('hash1', 'downloading')

          processor.process
        end
      end # context download in progress

      context 'download is complete' do

        let(:db_stub) do
          obj = double('database')
          obj.stub(:read_cache) { 'cache' }
          obj.stub(:update_cache) { true }
          obj.stub(:update_torrents) { true }
          #obj.stub(:update_torrent_state) { true }

          obj.stub(:execute) do |q|
            if q == 'SELECT hash, percent_progress, name FROM torrents WHERE tp_state IS NULL;'
              res = [
                #[ 'hash0', 'testTorrent0', 'download-dir', 'TV' ],
                [ 'hash1', 1000, 'testTorrent1' ]
              ]
            else
              res = []
            end
            res
          end

          obj
        end

        it 'changes state to downloaded' do
          utorrent_stub.stub(:set_job_properties)
          db_stub.should_receive(:update_torrent_state).with('hash1', 'downloaded')
          processor.process
        end
      end # context download is complete
    end # context torrent state is NULL

    context 'torrent state is downloading' do

      context 'torrent finished downloading' do

        let(:db_stub) do
          obj = double('database')
          obj.stub(:read_cache) { 'cache' }
          obj.stub(:update_cache) { true }
          obj.stub(:update_torrents) { true }
          #obj.stub(:update_torrent_state) { true }

          obj.stub(:execute) do |q|
            if q == 'SELECT hash, percent_progress, name FROM torrents WHERE tp_state = "downloading";'
              res = [
                #[ 'hash0', 'testTorrent0', 'download-dir', 'TV' ],
                [ 'hash1', 1000, 'testTorrent1' ]
              ]
            else
              res = []
            end
            res
          end

          obj
        end

        it 'changes state to downloaded' do
          db_stub.should_receive(:update_torrent_state).with('hash1', 'downloaded')
          processor.process
        end
      end # context torrent finished downloading
    end # context torrent state is downloading

    context 'torrent state is downloaded' do

      let(:db_stub) do
        obj = double('database')
        obj.stub(:read_cache) { 'cache' }
        obj.stub(:update_cache) { true }
        obj.stub(:update_torrents) { true }
        #obj.stub(:update_torrent_state) { true }

        obj.stub(:execute) do |q|
          if q == 'SELECT hash, name FROM torrents WHERE tp_state = "downloaded";'
            res = [
              #[ 'hash0', 'testTorrent0', 'download-dir', 'TV' ],
              [ 'hash1', 1000, 'testTorrent1' ]
            ]
          else
            res = []
          end
          res
        end

        obj
      end

      it 'changes state to processing' do
        db_stub.should_receive(:update_torrent_state).with('hash1', 'processing')
        processor.process
      end
    end # context torrent state is downloaded

    context 'torrent state is processing' do

      before do
        TorrentProcessor::Plugin::TorrentCopier.any_instance.stub(:execute)
        TorrentProcessor::Plugin::Unrar.any_instance.stub(:execute)
      end

      it 'runs processing plugins against the torrent' do
        TorrentProcessor::Plugin::TorrentCopier.any_instance.should_receive(:execute)
        TorrentProcessor::Plugin::Unrar.any_instance.should_receive(:execute)
        processor.process
      end

      it 'changes state to processed' do
        utorrent_stub.stub(:get_torrent_job_properties).and_return(
          {
            'props' =>
            [
              {
                'seed_override' => 1,
                'seed_ratio' => 0,
                'trackers' => 'my.test.tracker'
              }
            ]
          }
                                                                  )
        db_stub.stub(:execute) do |q|
          if q.include? 'processing'
            [
                [ 'hash1', 'testTorrent1', 'completed-dir', 'TV' ]
            ]
          else
            []
          end
        end
        db_stub.should_receive(:update_torrent_state).with('hash1', 'processed')

        processor.process
      end
    end # context torrent state is processing

    context 'torrent state is processed' do

      it 'changes state to seeding' do
        db_stub.stub(:execute) do |q|
          if q.include? 'processed'
            [
                [ 'hash1', 'testTorrent1' ]
            ]
          else
            []
          end
        end
        db_stub.should_receive(:update_torrent_state).with('hash1', 'seeding')

        processor.process
      end
    end # context torrent state is processed

    context 'torrent state is seeding' do

      it 'changes state to removing' do
        utorrent_stub.stub(:get_torrent_job_properties).and_return(
          {
            'props' =>
            [
              {
                'seed_override' => 1,
                'seed_ratio' => 0,
                'trackers' => 'my.test.tracker'
              }
            ]
          }
                                                                  )
        utorrent_stub.stub(:remove_torrent)
        db_stub.stub(:execute) do |q|
          if q.include? 'seeding'
            [
                [ 'hash1', 0, 'testTorrent1' ]
            ]
          else
            []
          end
        end
        db_stub.should_receive(:update_torrent_state).with('hash1', 'removing')

        processor.process
      end

      it 'send removal request to utorrent' do
        utorrent_stub.stub(:get_torrent_job_properties).and_return(
          {
            'props' =>
            [
              {
                'seed_override' => 1,
                'seed_ratio' => 0,
                'trackers' => 'my.test.tracker'
              }
            ]
          }
                                                                  )
        db_stub.stub(:execute) do |q|
          if q.include? 'seeding'
            [
                [ 'hash1', 0, 'testTorrent1' ]
            ]
          else
            []
          end
        end
        db_stub.should_receive(:update_torrent_state).with('hash1', 'removing')
        utorrent_stub.should_receive(:remove_torrent).with('hash1')

        processor.process
      end
    end # context torrent state is seeding

    context 'torrent state is removing' do

      context 'torrent has been removed from utorrent' do

        context 'utorrent has removal info' do

          it 'remove torrent from database' do
            utorrent_stub.stub(:torrents_removed?).and_return(true)
            utorrent_stub.stub(:removed_torrents).and_return({ 'hash1' => 'data' })
            db_stub.stub(:execute) do |q|
              if q.include? 'removing'
                [
                    [ 'hash1', 'testTorrent1' ]
                ]
              else
                []
              end
            end
            db_stub.should_receive(:delete_torrent).with('hash1')

            processor.process
          end
        end # context utorrent has removal info

        context 'utorrent does NOT have removal info' do

          it 'remove torrent from database' do
            utorrent_stub.stub(:torrents_removed?).and_return(false)
            utorrent_stub.stub(:torrents).and_return({})
            db_stub.stub(:execute) do |q|
              if q.include? 'removing'
                [
                    [ 'hash1', 'testTorrent1' ]
                ]
              else
                []
              end
            end
            db_stub.should_receive(:delete_torrent).with('hash1')

            processor.process
          end
        end # context utorrent does NOT have removal info
      end # context torrent has been removed from utorrent
    end # context torrent state is removing

    context 'torrent state is NOT removing' do

      context 'torrent has been removed from utorrent' do

        let(:torrent_data_stub) do
          obj = double('torrent_data')
          obj.stub(:name) { 'Awesome Show s1e05' }
          obj
        end

        it 'remove torrent from database' do
          utorrent_stub.stub(:torrents_removed?).and_return(true)
          utorrent_stub.stub(:removed_torrents).and_return({ 'hash1' => torrent_data_stub })
          db_stub.stub(:execute) do |q|
            []
          end
          db_stub.should_receive(:delete_torrent).with('hash1')

          processor.process
        end
      end # context torrent has been removed from utorrent
    end # context torrent state is NOT removing

    it 'moves completed movies' do
      TorrentProcessor::Plugin::MovieMover.any_instance.should_receive(:process)

      processor.process
    end # context move completed movies
  end # context #process
end
