require 'spec_helper'
require 'database_helper'
require 'utorrent_helper'

include TorrentProcessor::Plugin

describe RSSPlugin do

  include DatabaseHelper
  include UTorrentHelper

  subject(:plugin) { RSSPlugin.new }

  let(:args) do
    {
      :cmd      => cmd,
      :logger   => CaptureLogger,
      :database => database_stub(),
      :utorrent => utorrent_stub(),
    }
  end

  before(:each) do
    CaptureLogger.reset
  end

  describe '#rss_feeds' do

    let(:cmd) { '.rssfeeds' }

    it 'display current RSS feeds' do
      expect(plugin.rss_feeds(args)).to be_true
      expect( CaptureLogger.contains 'TestTorrent1Feed' )
      expect( CaptureLogger.contains 'TestTorrent2Feed' )
      expect( CaptureLogger.contains '2 Feed(s) found' )
    end
  end # #rss_feeds

  describe '#rss_filters' do

    let(:cmd) { '.rssfilters' }

    it 'display current RSS filters' do
      expect(plugin.rss_filters(args)).to be_true
      expect( CaptureLogger.contains 'TestTorrent1' )
      expect( CaptureLogger.contains 'TestTorrent2' )
      expect( CaptureLogger.contains '2 Filter(s) found' )
    end
  end # #rss_filters

  describe '#rss_feed_details' do

    let(:cmd) { '.feeddetails' }

    it 'display details of an RSS feed' do
      TorrentProcessor::Plugin::RSSPlugin.any_instance.stub(:getInput).and_return('0')
      expect(plugin.rss_feed_details(args)).to be_true
      expect( CaptureLogger.contains 'torrent_name: Test Torrent 1' )
      expect( CaptureLogger.contains 'torrent_name: Test Torrent 2' )
    end
  end # #rss_feed_details

  describe '#rss_filter_details' do

    let(:cmd) { '.filterdetails' }

    it 'display details of an RSS filter' do
      TorrentProcessor::Plugin::RSSPlugin.any_instance.stub(:getInput).and_return('0')
      expect(plugin.rss_filter_details(args)).to be_true
      expect( CaptureLogger.contains 'feed_name         : TestTorrent1' )
      expect( CaptureLogger.contains 'feed_name         : TestTorrent2' )
    end
  end # #rss_filter_details
end # RSSPlugin
