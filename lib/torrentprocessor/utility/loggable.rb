##############################################################################
# File::    loggable.rb
# Purpose:: Logging Mixin (module)
# 
# Author::    Jeff McAffee date
# Copyright:: Copyright (c) 2015, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

module TorrentProcessor::Utility
  module Loggable
    def logger
      @logger ||= NullLogger
    end

    def logger= logger_klass
      @logger = logger_klass
    end

    def log msg = ''
      @logger.log msg
    end
  end
end
