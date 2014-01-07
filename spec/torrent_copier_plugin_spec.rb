##############################################################################
# File::    torrent_copier_plugin_spec.rb
# Purpose:: TorrentCopierPlugin specification
# 
# Author::    Jeff McAffee 01/06/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require_relative './spec_helper'

include TorrentProcessor::ProcessorPlugin

describe TorrentCopierPlugin do

  context '#execute' do

    let(:ctx)           { Object.new }
    let(:torrent_data)  { Hash.new }

    it "must be overridden by child classes" do
      expect { TorrentCopierPlugin.new.execute(ctx, torrent_data) }.to raise_exception
    end
  end
end
