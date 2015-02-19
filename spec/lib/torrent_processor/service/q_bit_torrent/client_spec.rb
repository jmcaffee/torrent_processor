require 'spec_helper'

include TorrentProcessor::Service::QBitTorrent

describe Client do

  let(:ip) { '127.0.0.1' }
  let(:port) { 8083 }
  let(:user) { 'admin' }
  let(:pass) { 'abc' }

  let(:sut) { Client.new(ip, port, user, pass) }

  context "#new" do

    it "can be instantiated" do
      obj = Client.new(ip, port, user, pass)
    end
  end

  context "#new" do

    it "can be instantiated" do
      obj = Client.new(ip, port, user, pass)
    end
  end
end
