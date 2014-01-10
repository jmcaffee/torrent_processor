##############################################################################
# File::    processor_spec.rb
# Purpose:: Specification for Processor class
# 
# Author::    Jeff McAffee 01/08/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'spec_helper'

include TorrentProcessor

describe Processor do

  before(:all) do
    TorrentProcessor.configure
  end

  let(:processor) do
    obj = Processor.new(controller_stub)
    obj.utorrent = utorrent_stub
    obj
  end

  let(:controller_stub) do
    obj = double('controller')
    obj.stub(:cfg)      { cfg_stub }
    obj.stub(:logger)   { SimpleLogger }
    obj.stub(:database) { db_stub }
    obj
  end

  let(:cfg_stub) do
    {
      :ip => '127.0.0.1',
      :port => '8080',
      :user => 'xbmc',
      :pass => 's3cr3t',
    }
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
    obj.stub(:torrents) { [] }
    obj.stub(:torrents_removed?) { false }
    obj
  end

  let(:db_stub) do
    obj = double('database')
    obj.stub(:read_cache) { 'cache' }
    obj.stub(:update_cache) { true }
    obj.stub(:update_torrents) { true }

    obj.stub(:execute) do |q|
      if q == 'SELECT hash, name, folder, label FROM torrents WHERE tp_state = "processing";'
        res = [
          [ 'hash0', 'testTorrent0', 'download-dir', 'TV' ],
          [ 'hash1', 'testTorrent1', 'download-dir', 'TV' ]
        ]
      else
        res = []
      end
      res
    end

    obj
  end

  context '#new' do

    it 'instantiates a processor object' do
      Processor.new(controller_stub)
    end
  end

  context '#utorrent' do

    it 'instantiates an interface to uTorrent' do
      ut = processor.utorrent
    end
  end

  context '#process' do

    it 'processes tracked files in collaboration with uTorrent' do
      processor.process
    end
  end
end
