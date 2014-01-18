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

  context '#new' do

    it 'initializes services used by the app' do
      controller
      expect(Runtime.service.logger).to_not be nil
      expect(Runtime.service.database).to_not be nil
      expect(controller.setup).to_not be nil
    end
  end
end # describe Controller

