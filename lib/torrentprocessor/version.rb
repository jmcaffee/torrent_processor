##############################################################################
# Everything is contained in Module TorrentProcessor
#
module TorrentProcessor

  VERSION = "0.2.9" unless constants.include?("VERSION")
  APPNAME = "TorrentProcessor" unless constants.include?("APPNAME")
  COPYRIGHT = "Copyright (c) 2012, kTech Systems LLC. All rights reserved." unless constants.include?("COPYRIGHT")


  def self.logo()
    return  [ "#{TorrentProcessor::APPNAME} v#{TorrentProcessor::VERSION}",
              "#{TorrentProcessor::COPYRIGHT}",
              ""
            ].join("\n")
  end


end # module TorrentProcessor
