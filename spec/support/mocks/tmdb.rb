require 'rspec/mocks/standalone'

module Mocks

  def self.tmdb
    obj = double('tmdb')
    allow(obj).to receive(:connect)  { true }
    allow(obj).to receive(:close)    { true }

    obj
  end

  def self.tmdb_class
    allow_any_instance_of(TorrentProcessor::Plugin::MovieDB).to receive(:test_connection).and_return(true)
    allow_any_instance_of(TorrentProcessor::Plugin::MovieDB).to receive(:search_movie).and_return([])
  end
end
