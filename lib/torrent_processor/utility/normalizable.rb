##############################################################################
# File::    normalizable.rb
# Purpose:: Normalize floating point percentages
# 
# Author::    Jeff McAffee 02/27/2015
# Copyright:: Copyright (c) 2015, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################


module TorrentProcessor
  module Utility
    module Normalizable

      ###
      # Normalize percentages to integers
      # After normalization, 100% = 1000
      #

      def normalize_percent percent
        percent = Float(percent)
        (percent * 1000.0).floor
      end
    end
  end
end

