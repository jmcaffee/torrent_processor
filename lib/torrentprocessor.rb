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

module TorrentProcessor
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
  end

  def self.load_configuration cfg_file
    @configuration = YAML.load_file(cfg_file)
  end

  def self.save_configuration cfg_file
    File.open(cfg_file, 'w') do |out|
      YAML.dump(configuration, out)
    end
  end

  class Configuration
    attr_accessor :utorrent
    attr_accessor :tmdb

    def initialize
      @utorrent = UTorrentConfiguration.new
      @tmdb = TMdbConfiguration.new
    end

    class UTorrentConfiguration
      attr_accessor :ip
      attr_accessor :port
      attr_accessor :user
      attr_accessor :pass
      attr_accessor :dir_completed_download
      attr_accessor :seed_ratio
    end

    class TMdbConfiguration
      attr_accessor :api_key
      attr_accessor :language
    end
  end
end


TorrentProcessor.configure do |config|
  config.tmdb.language = 'en'
end

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


