##############################################################################
# File::    unrar_plugin_spec.rb
# Purpose:: UnrarPlugin (console) specification
# 
# Author::    Jeff McAffee 01/08/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require_relative '../spec_helper'

include TorrentProcessor

describe ConsolePlugin::UnrarPlugin do

    let(:unrar_plug)  { ConsolePlugin::UnrarPlugin.new }

    let(:console_stub) do
      obj = double("console")
      obj.stub(:logger) { SimpleLogger }
      obj.stub(:cfg)    do
        { :otherprocessing => torrent_dir, :tvprocessing => torrent_dir, :movieprocessing => torrent_dir }
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
        :filedir => 'tmp/spec/unrar_plugin_console/completed/multi-rar',
        :label => 'TV'
      }
    end

  context '#new' do

    it 'instantiates a plugin instance' do
      obj = ConsolePlugin::UnrarPlugin.new
    end
  end

  context '#unrar' do

      let(:torrent_dir)  { 'tmp/spec/unrar_plugin_console/target' }
      let(:torrent_file) { File.join( torrent_dir, 'test_250kb.avi' ) }

      before(:each) do
        blocking_dir_delete(torrent_dir)
        create_downloaded_torrent('spec/data/multi_rar', torrent_dir)
      end

    it 'raises an exception if caller is not provided' do
      expect { unrar_plug.unrar [] }.to raise_exception
    end

    context 'given a path' do

      it 'unrars an archive' do
        unrar_plug.unrar([torrent_dir, console_stub])
        expect(File.exists?(torrent_file)).to be true
      end
    end

    context 'given a torrent ID' do

      it 'unrars an archive' do
        unrar_plug.unrar(['1', console_stub])
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
end
