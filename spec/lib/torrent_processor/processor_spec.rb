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

  let(:utorrent_stub) { Mocks.utorrent }
  let(:db_stub) { Mocks.db }

  let(:args) do
    {
      #:logger     => SimpleLogger,
      :cfg        => Mocks.cfg,
      :moviedb    => Mocks.tmdb,
      :webui      => utorrent_stub,
      :webui_type => :utorrent,
      :database   => db_stub,
    }
  end

  describe '#new' do

    it 'instantiates a processor object' do
      Processor.new(
        #:logger     => SimpleLogger,
        :cfg        => Mocks.cfg,
        :moviedb    => Mocks.tmdb,
        :webui      => Mocks.utorrent,
        :webui_type => :utorrent,
        :database   => Mocks.db )
    end
  end

  describe '#process' do

    context 'plugin raises exception' do

      it 'aborts processing the torrent' do
        allow_any_instance_of(TorrentProcessor::Plugin::TorrentCopier).to receive(:execute) {
          raise TorrentProcessor::Plugin::PluginError, 'an exception'
        }

        processor.process
      end
    end # context plugin raises exception

    context 'torrent state is NULL' do

      context 'download in progress' do

        it 'applies seed limit filters to new torrents and changes state to downloading' do
          # Override cfg mock to return appropriate filters.
          allow(Mocks.cfg).to receive(:filters) { { 'test' => '0' } }
          allow(utorrent_stub).to receive(:get_utorrent_settings).and_return(
              [
                ['seed_ratio', 0, 0],
                ['dir_completed_download', 1, 'completed-dir']
              ]
          )
          allow(utorrent_stub).to receive(:get_torrent_job_properties).and_return(
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
          )
          expect(utorrent_stub).to receive(:set_job_properties).with(
            {
              'hash1' =>
              {
                'seed_override' => 1,
                'seed_ratio' => 0
              }
            }
          )
          allow(db_stub).to receive(:execute) do |q|
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
          expect(db_stub).to receive(:update_torrent_state).with('hash1', 'downloading')

          processor.process
        end
      end # context download in progress

      context 'download is complete' do

        it 'changes state to downloaded' do
          allow(utorrent_stub).to receive(:set_job_properties)
          allow(utorrent_stub).to receive(:get_utorrent_settings).and_return(
              [
                ['seed_ratio', 0, 0],
                ['dir_completed_download', 1, 'completed-dir']
              ]
          )
          allow(utorrent_stub).to receive(:get_torrent_job_properties).and_return(
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
          )
          allow(db_stub).to receive(:execute) do |q|
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
          expect(db_stub).to receive(:update_torrent_state).with('hash1', 'downloaded')
          processor.process
        end
      end # context download is complete
    end # context torrent state is NULL

    context 'torrent state is downloading' do

      context 'torrent finished downloading' do

        it 'changes state to downloaded' do
          allow(db_stub).to receive(:execute) do |q|
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
          expect(db_stub).to receive(:update_torrent_state).with('hash1', 'downloaded')

          processor.process
        end
      end # context torrent finished downloading
    end # context torrent state is downloading

    context 'torrent state is downloaded' do

      it 'changes state to processing' do
        allow(db_stub).to receive(:execute) do |q|
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
        expect(db_stub).to receive(:update_torrent_state).with('hash1', 'processing')
        processor.process
      end
    end # context torrent state is downloaded

    context 'torrent state is processing' do

      before do
        allow_any_instance_of(TorrentProcessor::Plugin::TorrentCopier).to receive(:execute)
        allow_any_instance_of(TorrentProcessor::Plugin::Unrar).to receive(:execute)
      end

      it 'runs processing plugins against the torrent' do
        allow(db_stub).to receive(:execute) do |q|
          if q.include? 'processing'
            [
                [ 'hash1', 'testTorrent1', 'completed-dir', 'TV' ]
            ]
          else
            []
          end
        end
        expect(db_stub).to receive(:update_torrent_state).with('hash1', 'processed')
        expect_any_instance_of(TorrentProcessor::Plugin::TorrentCopier).to receive(:execute)
        expect_any_instance_of(TorrentProcessor::Plugin::Unrar).to receive(:execute)
        processor.process
      end

      it 'changes state to processed' do
        allow(utorrent_stub).to receive(:get_torrent_job_properties).and_return(
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
        allow(db_stub).to receive(:execute) do |q|
          if q.include? 'processing'
            [
                [ 'hash1', 'testTorrent1', 'completed-dir', 'TV' ]
            ]
          else
            []
          end
        end
        expect(db_stub).to receive(:update_torrent_state).with('hash1', 'processed')

        processor.process
      end
    end # context torrent state is processing

    context 'torrent state is processed' do

      it 'changes state to seeding' do
        allow(db_stub).to receive(:execute) do |q|
          if q.include? 'processed'
            [
                [ 'hash1', 'testTorrent1' ]
            ]
          else
            []
          end
        end
        expect(db_stub).to receive(:update_torrent_state).with('hash1', 'seeding')

        processor.process
      end
    end # context torrent state is processed

    context 'torrent state is seeding' do

      it 'changes state to removing' do
        allow(utorrent_stub).to receive(:get_torrent_job_properties).and_return(
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
        allow(db_stub).to receive(:execute) do |q|
          if q.include? 'seeding'
            [
                [ 'hash1', 0, 'testTorrent1' ]
            ]
          else
            []
          end
        end
        expect(db_stub).to receive(:update_torrent_state).with('hash1', 'removing')

        processor.process
      end

      it 'send removal request to utorrent' do
        allow(utorrent_stub).to receive(:get_torrent_job_properties).and_return(
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
        allow(db_stub).to receive(:execute) do |q|
          if q.include? 'seeding'
            [
                [ 'hash1', 0, 'testTorrent1' ]
            ]
          else
            []
          end
        end
        expect(db_stub).to receive(:update_torrent_state).with('hash1', 'removing')
        expect(utorrent_stub).to receive(:remove_torrent).with('hash1')

        processor.process
      end
    end # context torrent state is seeding

    context 'torrent state is removing' do

      context 'torrent has been removed from utorrent' do

        context 'utorrent has removal info' do

          it 'remove torrent from database' do
            allow(utorrent_stub).to receive(:torrents_removed?).and_return(true)
            allow(utorrent_stub).to receive(:removed_torrents).and_return({ 'hash1' => 'data' })
            allow(db_stub).to receive(:execute) do |q|
              if q.include? 'removing'
                [
                    [ 'hash1', 'testTorrent1' ]
                ]
              else
                []
              end
            end
            expect(db_stub).to receive(:delete_torrent).with('hash1')

            processor.process
          end
        end # context utorrent has removal info

        context 'utorrent does NOT have removal info' do

          it 'remove torrent from database' do
            allow(utorrent_stub).to receive(:torrents).and_return({})
            allow(db_stub).to receive(:execute) do |q|
              if q.include? 'removing'
                [
                    [ 'hash1', 'testTorrent1' ]
                ]
              else
                []
              end
            end
            expect(db_stub).to receive(:delete_torrent).with('hash1')

            processor.process
          end
        end # context utorrent does NOT have removal info
      end # context torrent has been removed from utorrent
    end # context torrent state is removing

    context 'torrent state is NOT removing' do

      context 'torrent has been removed from utorrent' do

        let(:torrent_data_stub) do
          obj = double('torrent_data')
          allow(obj).to receive(:name) { 'Awesome Show s1e05' }
          obj
        end

        it 'remove torrent from database' do
          allow(utorrent_stub).to receive(:torrents_removed?).and_return(true)
          allow(utorrent_stub).to receive(:removed_torrents).and_return({ 'hash1' => torrent_data_stub })
          allow(db_stub).to receive(:execute) do |q|
            []
          end
          expect(db_stub).to receive(:delete_torrent).with('hash1')

          processor.process
        end
      end # context torrent has been removed from utorrent
    end # context torrent state is NOT removing

    it 'moves completed movies' do
      expect_any_instance_of(TorrentProcessor::Plugin::MovieMover).to receive(:process)

      processor.process
    end # context move completed movies
  end # context #process
end
