##############################################################################
# File::    console_spec.rb
# Purpose:: Console specification
#
# Author::    Jeff McAffee 01/08/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'spec_helper'

include TorrentProcessor

describe Console do

  subject(:console) { Console.new(controller_stub) }

  let(:controller_stub) do
    obj = double('controller')
    obj.stub(:cfg) do
      {}
    end
    obj.stub(:database) { db_stub }
    obj
  end

  let(:db_stub) do
    obj = double('database')
    obj.stub(:close) { true }
    obj
  end

  context '#new' do

    it 'instantiates a console object' do
      Console.new(controller_stub)
    end
  end

  context '#execute' do

    it 'starts the console' do
      console.execute
    end
  end

  context '#process_cmd' do

    context 'cmd: .testcon' do

      it "'.testcon' tests the uTorrent connection" do
        console.process_cmd '.testcon'
      end
    end

    context 'TMdb comands' do

      TorrentProcessor.configure do |config|
        config.tmdb.api_key = '***REMOVED***'
      end

      context 'cmd: .tmdbtestcon' do

        it "'.tmdbtestcon' tests the TMdb connection" do
          console.process_cmd '.tmdbtestcon'
        end
      end

      context 'cmd: .tmdbmoviesearch' do

        it "'.tmdbmoviesearch' searches for a movie" do
          console.process_cmd '.tmdbmoviesearch fight club'
          #console.process_cmd '.tmdbmoviesearch'
        end
      end
    end
  end
end
