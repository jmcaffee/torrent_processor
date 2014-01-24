##############################################################################
# File::    controller_spec.rb
# Purpose:: Controller class specification
# 
# Author::    Jeff McAffee 01/15/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'spec_helper'
include TorrentProcessor

describe Controller do

  subject(:controller) { Controller.new }

  let(:db_stub) do
    obj = double('database')
    obj
  end

  #let(:logger) { SimpleLogger }
  let(:logger) { NullLogger }

  let(:setup_args) do
    {
      #:logger => logger,
      :database => db_stub
    }
  end

  describe '#new' do

    it 'initializes services used by the app' do
      controller
      expect(Runtime.service.logger).to_not be nil
      expect(Runtime.service.database).to_not be nil
      expect(Runtime.service.utorrent).to_not be nil
      expect(Runtime.service.moviedb).to_not be nil
      expect(Runtime.service.processor).to_not be nil
      expect(Runtime.service.console).to_not be nil
      expect(controller.setup).to_not be nil
    end
  end

  describe '#process' do

    before(:each) do
      FileLogger.stub(:log)
      TorrentProcessor::Processor.any_instance.stub(:process)
    end

    context 'setup has not been completed' do

      before(:each) do
        TorrentProcessor::TPSetup.any_instance.stub(:check_setup_completed) { false }
      end

      it "exits program" do
        TorrentProcessor::Processor.any_instance.should_not_receive(:process)

        expect { controller.process }.to raise_exception
      end
    end

    context 'setup has been completed' do

      before(:each) do
        TorrentProcessor::TPSetup.any_instance.stub(:check_setup_completed) { true }
      end

      it "calls Processor#process" do
        TorrentProcessor::Processor.any_instance.should_receive(:process)

        controller.process
      end
    end
  end
end # describe Controller

