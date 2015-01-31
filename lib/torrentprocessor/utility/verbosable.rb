##############################################################################
# File::    verbosable.rb
# Purpose:: Verbose Flag Mixin (module)
# 
# Author::    Jeff McAffee date
# Copyright:: Copyright (c) 2015, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

module TorrentProcessor::Utility
  module Verbosable
    def verbose
      @verbose ||= false
    end

    def verbose= flag
      @verbose = flag
    end
  end
end
