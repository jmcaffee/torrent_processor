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
      :logger     => CaptureLogger,
      :utorrent   => Mocks.utorrent,
      :database   => Mocks.db,
      :processor  => processor_stub
    }
  end

  let(:tmp_path) do
    pth = 'tmp/spec/console'
    mkpath pth
    pth
  end

  let(:processor_stub) do
    obj = double('processor')
    obj
  end

  describe '#new' do

    it 'instantiates a console object' do
      Console.new(
        :logger   => CaptureLogger,
        :utorrent => Mocks.utorrent,
        :database => Mocks.db,
        :processor => processor_stub)
    end
  end

  describe '#execute' do

    it 'starts the console' do
      allow_any_instance_of(TorrentProcessor::Console).to receive(:getInput).and_return('.exit')
      console.execute
    end
  end

  describe '#process_cmd' do

    context 'TMdb comands' do

      describe 'cmd: .tmdbtestcon' do

        it "tests the TMdb connection" do
          Mocks.tmdb_class
          console.process_cmd '.tmdbtestcon'
        end
      end

      describe 'cmd: .tmdbmoviesearch' do

        it "searches for a movie" do
          Mocks.tmdb_class
          console.process_cmd '.tmdbmoviesearch fight club'
        end
      end
    end

    context 'Unrar commands' do

      describe 'cmd .unrar' do

        before(:each) do
          CaptureLogger.reset
        end

        context 'no path or ID provided' do

          it 'displays an error message when path or id not provided' do
            console.process_cmd '.unrar'

            expect(CaptureLogger.messages.include?('Error: path to directory or torrent ID expected')).to be_truthy
          end
        end # no path or ID

        context 'path provided' do

          it 'unrars archive' do
            console.process_cmd '.unrar blah'

            expect(CaptureLogger.messages.include?('Error: path to directory or torrent ID expected')).to be_falsey
          end
        end # path provided
      end # cmd .unrar
    end # Unrar commands
  end
end
