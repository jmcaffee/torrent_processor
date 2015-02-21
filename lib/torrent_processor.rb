##############################################################################
# File::    torrent_processor.rb
# Purpose:: Include file for TorrentProcessor library
#
# Author::    Jeff McAffee 07/31/2011
# Copyright:: Copyright (c) 2011, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'find'
require 'logger'
require 'ktutils/os'
require 'torrent_processor/version'

module TorrentProcessor
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
  end

  def self.load_configuration cfg_file
    if File.exist? cfg_file
      @configuration = YAML.load_file(cfg_file)
    #else
    #  @configuration = Configuration.new
    end
  end

  def self.save_configuration cfg_file = nil
    if cfg_file.nil?
      if configuration.app_path.nil? || configuration.app_path.empty?
        raise ArgumentError, 'Filename must be provided if app_path not provided'
      end

      cfg_file = File.join(configuration.app_path, 'config.yml')
    end

    raise ArgumentError, 'Directory provided. Need file path' if File.directory?(cfg_file)

    File.open(cfg_file, 'w') do |out|
      YAML.dump(configuration, out)
    end
  end

  class Configuration
    attr_accessor :version
    attr_accessor :app_path
    attr_accessor :logging
    attr_accessor :max_log_size
    attr_accessor :log_dir
    attr_accessor :tv_processing
    attr_accessor :movie_processing
    attr_accessor :other_processing
    attr_accessor :filters

    attr_accessor :backend
    attr_accessor :utorrent
    attr_accessor :qbtorrent
    attr_accessor :tmdb

    def initialize
      @version = 2
      @backend = :qbtorrent
      @utorrent = UTorrentConfiguration.new
      @qbtorrent = QBitTorrentConfiguration.new
      @tmdb = TMdbConfiguration.new
      @filters = {}
    end

    class UTorrentConfiguration
      attr_accessor :ip
      attr_accessor :port
      attr_accessor :user
      attr_accessor :pass
      attr_accessor :dir_completed_download
      attr_accessor :seed_ratio
    end

    class QBitTorrentConfiguration
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
      attr_accessor :target_movies_path
      attr_accessor :can_copy_start_time
      attr_accessor :can_copy_stop_time
    end
  end
end


TorrentProcessor.configure do |config|
  if Ktutils::OS.windows?
    config.app_path       = File.join(ENV['APPDATA'].gsub('\\', '/'), 'torrentprocessor')
  else
    config.app_path       = File.join(ENV['HOME'], '.torrentprocessor')
  end
  config.log_dir        = config.app_path

  config.tmdb.language  = 'en'
end

##############################################################################
# Require each lib file
#
require 'torrent_processor/utility'
require 'torrent_processor/service'
require 'torrent_processor/controller'
require 'torrent_processor/processor'
require 'torrent_processor/runtime'
require 'torrent_processor/tp_setup'
require 'torrent_processor/database'
require 'torrent_processor/console'
require 'torrent_processor/plugin'
require 'torrent_processor/torrent_app'

# If compiling with OCRA we want these gems available to us so we need
# to require them.
if defined? Ocra
  require 'pry'
  require 'rb-readline'
  require 'pry-nav'
  require 'pry-rescue'
  require 'pry-stack_explorer'
end

