require 'spec_helper'

include TorrentProcessor

describe Console do

  subject(:console) { Console.new(init_args) }

  let(:init_args) do
    {
      :logger => CaptureLogger,
      :utorrent => Mocks.utorrent,
      :database => Mocks.db,
    }
  end

  describe '#process_cmd' do

    before(:each) { CaptureLogger.reset }

    context 'cmd: .rssfeeds' do

      it 'display current RSS feeds' do
        expect(console.process_cmd('.rssfeeds')).to be_truthy
      end
    end # cmd: .rssfeeds

    context 'cmd: .rssfilters' do

      it 'display current RSS filters' do
        expect(console.process_cmd('.rssfilters')).to be_truthy
      end
    end # cmd: .rssfilters

    context 'cmd: .feeddetails' do

      it 'display details of an RSS feed' do
        TorrentProcessor::Plugin::RSSPlugin.any_instance.stub(:getInput).and_return('0')
        expect(console.process_cmd('.feeddetails')).to be_truthy
      end
    end # cmd: .feeddetails

    context 'cmd: .filterdetails' do

      it 'display details of an RSS filter' do
        TorrentProcessor::Plugin::RSSPlugin.any_instance.stub(:getInput).and_return('0')
        expect(console.process_cmd('.filterdetails')).to be_truthy
      end
    end # cmd: .filterdetails
  end # #process_cmd
end #
