##############################################################################
# File::    service.rb
# Purpose:: Service module/classes
#
# Author::    Jeff McAffee 2014-02-04
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

##########################################################################
# TorrentProcessor module
module TorrentProcessor::Service
end # module TorrentProcessor::Service

require_relative('service/utorrent')
require_relative 'service/qbittorrent'
require_relative('service/robocopy')
require_relative('service/seven_zip')

