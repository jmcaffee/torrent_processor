##############################################################################
# Everything is contained in Module TorrentProcessor
#
module TorrentProcessor

  require 'date'

  VERSION = "0.3.2" unless constants.include?("VERSION")
  APPNAME = "TorrentProcessor" unless constants.include?("APPNAME")
  COPYRIGHT = "Copyright (c) #{Date.today.year}, kTech Systems LLC. All rights reserved." unless constants.include?("COPYRIGHT")

  DB_VERSION = 1 unless defined?(DB_VERSION)


  def self.logo()
    return  [ "#{TorrentProcessor::APPNAME} v#{TorrentProcessor::VERSION}",
              "#{TorrentProcessor::COPYRIGHT}",
              ""
            ].join("\n")
  end


end # module TorrentProcessor
