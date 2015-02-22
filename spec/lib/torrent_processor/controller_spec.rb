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

  subject(:controller) do
    allow_any_instance_of(TorrentProcessor::TPSetup).to receive(:app_data_path).and_return(work_dir)
    generate_configuration(work_dir)
    Controller.new
  end

  let(:work_dir) do
    spec_tmp_dir('controller').to_s
  end

  #let(:logger) { SimpleLogger }
  let(:logger) { NullLogger }

  let(:setup_args) do
    {
      #:logger => logger,
      :database => Mocks.db
    }
  end

  describe '#new' do

    context 'utorrent backend' do

      subject(:controller) do
        allow_any_instance_of(TorrentProcessor::TPSetup).to receive(:app_data_path).and_return(work_dir)

        generate_configuration(work_dir) do |config|
          config.backend = :utorrent
        end

        Controller.new
      end

      it 'initializes services used by the app' do
        controller
        expect(Runtime.service.logger).to_not be nil
        expect(Runtime.service.database).to_not be nil
        expect(Runtime.service.webui).to_not be nil
        expect(Runtime.service.webui.class).to be TorrentProcessor::Service::UTorrent::UTorrentWebUI
        expect(Runtime.service.webui_type).to eq :utorrent
        expect(Runtime.service.moviedb).to_not be nil
        expect(Runtime.service.processor).to_not be nil
        expect(Runtime.service.console).to_not be nil
        expect(controller.setup).to_not be nil
      end
    end

    context 'qbtorrent backend' do

      subject(:controller) do
        allow_any_instance_of(TorrentProcessor::TPSetup).to receive(:app_data_path).and_return(work_dir)

        generate_configuration(work_dir) do |config|
          config.backend = :qbtorrent
        end

        Controller.new
      end

      it 'initializes services used by the app' do
        controller
        expect(Runtime.service.logger).to_not be nil
        expect(Runtime.service.database).to_not be nil
        expect(Runtime.service.webui).to_not be nil
        expect(Runtime.service.webui.class).to be ::QbtClient::WebUI
        expect(Runtime.service.webui_type).to eq :qbtorrent
        expect(Runtime.service.moviedb).to_not be nil
        expect(Runtime.service.processor).to_not be nil
        expect(Runtime.service.console).to_not be nil
        expect(controller.setup).to_not be nil
      end
    end
  end

  describe '#process' do

    before(:each) do
      allow(FileLogger).to receive(:log)
      allow_any_instance_of(TorrentProcessor::Processor).to receive(:process)
    end

    context 'setup has not been completed' do

      before(:each) do
        allow_any_instance_of(TorrentProcessor::TPSetup).to receive(:check_setup_completed).and_return(false)
      end

      it "exits program" do
        expect_any_instance_of(TorrentProcessor::Processor).not_to receive(:process)

        expect { controller.process }.to raise_exception
      end
    end

    context 'setup has been completed' do

      before(:each) do
        allow_any_instance_of(TorrentProcessor::TPSetup).to receive(:check_setup_completed).and_return(true)
      end

      it "calls Processor#process" do
        expect_any_instance_of(TorrentProcessor::Processor).to receive(:process)

        controller.process
      end
    end
  end
end # describe Controller

