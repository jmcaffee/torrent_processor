##############################################################################
# File::    torrentprocessor.rb
# Purpose:: Include file for TorrentProcessor library
#
# Author::    Jeff McAffee 07/31/2011
# Copyright:: Copyright (c) 2011, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'find'
require 'logger'
require 'win32ole'


##############################################################################
# Logging
#
if(!$LOG)
  $LOG = Logger.new(STDERR)
  $LOG.level = Logger::ERROR
end

# $LOGGING should be false when releasing a production build.
# Turning on logging will also result in stack traces being displayed when
# exceptions are thrown.

$LOGGING = false
$LOGGING = true           # Uncomment this line to force logging


require "#{File.join( File.dirname(__FILE__), 'torrentprocessor','config')}"
  logcfg = TorrentProcessor::Config.new.load
  if(logcfg.key?(:logging) && (true == logcfg[:logging]) )
    $LOGGING = true
  end

  if($LOGGING)
    # Create a new log file each time:
    file = File.open('torrentprocessor.log', File::WRONLY | File::APPEND | File::CREAT | File::TRUNC)
    $LOG = Logger.new(file)
    $LOG.level = Logger::DEBUG
    #$LOG.level = Logger::INFO
  else
    if(File.exists?('torrentprocessor.log'))
      FileUtils.rm('torrentprocessor.log')
    end
  end
  $LOG.info "**********************************************************************"
  $LOG.info "Logging started for TorrentProcessor library."
  $LOG.info "**********************************************************************"


##############################################################################
# Require each lib file
#
class_files = File.join( File.dirname(__FILE__), 'torrentprocessor', '*.rb')
$: << File.join( File.dirname(__FILE__), 'torrentprocessor')  # Add directory to the include file array.
Dir.glob(class_files) do | class_file |
  require class_file[/\w+\.rb$/]
end


