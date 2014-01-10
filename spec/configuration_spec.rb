##############################################################################
# File::    configuration_spec.rb
# Purpose:: TorrentProcessor::configuration specification
# 
# Author::    Jeff McAffee 01/07/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'spec_helper'

describe TorrentProcessor do

  context '.configuration' do

    it 'returns a configuration object' do
      expect(TorrentProcessor.configuration).to_not be nil
    end

    context '#utorrent' do

      it 'returns a UTorrentConfiguration object' do
        expect(TorrentProcessor.configuration.utorrent).to_not be nil
      end

      context '#dir_completed_download' do

        let(:test_dir)  { 'some/test/dir' }

        it 'sets and retains a value' do
          TorrentProcessor.configure do |config|
            config.utorrent.dir_completed_download = test_dir
          end

          expect(TorrentProcessor.configuration.utorrent.dir_completed_download).to eq test_dir
        end
      end

      context '#seed_ratio' do

        let(:test_ratio)  { '1500' }

        it 'sets and retains a value' do
          TorrentProcessor.configure do |config|
            config.utorrent.seed_ratio = test_ratio
          end

          expect(TorrentProcessor.configuration.utorrent.seed_ratio).to eq test_ratio
        end
      end
    end
  end
end
