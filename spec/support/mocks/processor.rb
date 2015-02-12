require 'rspec/mocks/standalone'

module Mocks

  def self.processor
    obj = double('processor')
    allow(obj).to receive(:process)

    obj
  end

  def self.processor_class
    allow_any_instance_of(TorrentProcessor::Plugin::MovieDB).to receive(:test_connection).and_return(true)
    allow_any_instance_of(TorrentProcessor::Plugin::MovieDB).to receive(:search_movie).and_return([])
  end
end
