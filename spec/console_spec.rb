##############################################################################
# File::    console_spec.rb
# Purpose:: Console specification
#
# Author::    Jeff McAffee 01/08/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

###
# FIXME: This is a 'bad' specification. It should only test the in/out interface
# and it actually contains many tests touching dependent plugins.
# This should be fixed.
###


require 'spec_helper'

include TorrentProcessor

describe Console do

  subject(:console) { Console.new(args) }

  let(:args) do
    {
      :utorrent => utorrent_stub,
      :database => db_stub,
      :processor => processor_stub
    }
  end

  let(:tmp_path) do
    pth = 'tmp/spec/console'
    mkpath pth
    pth
  end

  let(:utorrent_stub) do
    obj = double('utorrent')
    obj.stub(:get_torrent_list) { [] }
    obj.stub(:torrents) { [] }
    obj.stub(:get_utorrent_settings) { [] }
    obj.stub(:settings) { [] }
    obj
  end

  let(:db_stub) do
    obj = double('database')
    obj.stub(:close) { true }
    obj
  end

  let(:processor_stub) do
    obj = double('processor')
    obj
  end

  describe '#new' do

    it 'instantiates a console object' do
      Console.new(
        :utorrent => utorrent_stub,
        :database => db_stub,
        :processor => processor_stub)
    end
  end

  describe '#execute' do

    it 'starts the console' do
      TorrentProcessor::Console.any_instance.stub(:getInput).and_return('.exit')
      console.execute
    end
  end

  describe '#process_cmd' do

    context 'uTorrent commands' do

      describe 'cmd: .testcon' do

        it "tests the uTorrent connection" do
          console.process_cmd '.testcon'
        end
      end

      describe 'cmd: .utsettings' do

        it "returns current uTorrent settings" do
          console.process_cmd '.utsettings'
        end
      end

      describe 'cmd: .jobprops' do

        it "returns current uTorrent job properties" do
          console.process_cmd '.jobprops'
        end
      end

      describe 'cmd: .tlist' do

        it "returns a list of torrents uTorrent is monitoring" do
          console.process_cmd '.tlist'
        end
      end

      describe 'cmd: .tnames' do

        it "display names of torrents in uTorrent" do
          console.process_cmd '.tnames'
        end
      end

      describe 'cmd: .tdetails' do

        it "display torrent details" do
          console.process_cmd '.tdetails'
        end
      end

      describe 'cmd: .listquery' do

        it "return response output of list query" do
          console.process_cmd '.listquery'
        end
      end
    end # context uTorrent commands

    context 'TMdb comands' do

      TorrentProcessor.configure do |config|
        config.tmdb.api_key = '***REMOVED***'
      end

      describe 'cmd: .tmdbtestcon' do

        it "tests the TMdb connection" do
          console.process_cmd '.tmdbtestcon'
        end
      end

      describe 'cmd: .tmdbmoviesearch' do

        it "searches for a movie" do
          console.process_cmd '.tmdbmoviesearch fight club'
          #console.process_cmd '.tmdbmoviesearch'
        end
      end
    end
  end
end
