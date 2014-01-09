##############################################################################
# File::    console_spec.rb
# Purpose:: Console specification
#
# Author::    Jeff McAffee 01/08/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require_relative './spec_helper'

include TorrentProcessor

describe Console do

  let(:controller_stub) do
    obj = double('controller')
    obj.stub(:cfg) do
      {}
    end
    obj.stub(:database) { Object.new }
    obj
  end

  context '#new' do

    it 'instantiates a console object' do
      Console.new(controller_stub)
    end
  end
end
