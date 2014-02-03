##############################################################################
# File::    torrentprocessorcfg.rb
# Purpose:: TorrentProcessor configuration file reader/writer class.
#
# Author::    Jeff McAffee 07/31/2011
# Copyright:: Copyright (c) 2011, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'ktcommon/ktcfg'
require 'torrentprocessor/version'


module TorrentProcessor

  ##########################################################################
  # Config class
  class Config < KtCfg::CfgFile

  attr_accessor :cfg
  attr_writer   :cfgFile


    ###
    # Config class constructor
    #
    def initialize(rootDir=nil)
      $LOG.debug "Config::initialize"
      super
      @cfg = {}

      setDefaults()
    end


    ###
    # Set default config values
    #
    def setDefaults
      $LOG.debug "Config::setDefaults"

      # Notes about APPDATA paths:
      # Local app data should be used when an app's data is too
      # big to move around. Or is specific to the machine running
      # the application.
      #
      # Roaming app data files could be pushed to a server (in a
      # domain environment) and downloaded onto a different work
      # station.
      #
      # LocalLow is used for data that must be sandboxed. Currently
      # it is only used by IE for addons and storing data from
      # untrusted sources (as far as I know).
      #


      appDataPath = ENV["APPDATA"]          # APPDATA returns AppData\Roaming on Vista/W7
      #appDataPath = ENV["LOCALAPPDATA"]        # LOCALAPPDATA returns AppData\Local on Vista/W7
      appDataPath = File.rubypath(File.join(appDataPath, "torrentprocessor"))
      @cfg[:appPath] = appDataPath
      @cfg[:version]  = TorrentProcessor::VERSION
      @cfg[:logging]  = false
      @cfg[:filters] = {}
      @cfg[:tmdb_api_key] = ''
      @cfg[:target_movies_path] = ''
      @cfg[:can_copy_start_time] = '00:00'
      @cfg[:can_copy_stop_time] = '23:59'

      @cfgFile = "torrentprocessor.yml"

      # Set the config file path. Default is the 'global' one in APPDATA.
      if( @rootDir.nil? )
        @rootDir = appDataPath
        @cfgFile = "config.yml"

        # Override the gobal config if there is a local (current working dir) version.
        if(File.exists?(File.join(FileUtils.pwd(), "torrentprocessor.yml")))
          @rootDir = FileUtils.pwd()
          @cfgFile = "torrentprocessor.yml"
        end
      else
        if File.exists?(File.join(@rootDir, 'config.yml'))
          @cfgFile = 'config.yml'
        end
      end
    end


    # Load the YAML configuration file.
    # returns:: a hash containing configuration info.
    def load
      $LOG.debug "Config::load"
      tmpCfg = read(@cfgFile)
      @cfg = tmpCfg if !tmpCfg.nil? && tmpCfg != false && !tmpCfg.empty?
      @cfg
    end


    # Save the @cfg hash to a YAML file.
    def save
      $LOG.debug "Config::save"
      write(@cfgFile, @cfg)
    end


  end # class Config


end # module TorrentProcessor
