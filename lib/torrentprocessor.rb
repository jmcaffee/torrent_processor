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
    attr_accessor :app_path
    attr_accessor :logging
    attr_accessor :max_log_size
    attr_accessor :log_dir
    attr_accessor :tv_processing
    attr_accessor :movie_processing
    attr_accessor :other_processing
    attr_accessor :filters

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
      attr_accessor :target_movies_path
      attr_accessor :can_copy_start_time
      attr_accessor :can_copy_stop_time
    end
  end
end


TorrentProcessor.configure do |config|
  config.app_path       = File.join(ENV['APPDATA'].gsub('\\', '/'), 'torrentprocessor')
  config.log_dir        = config.app_path

  config.tmdb.language  = 'en'
end

##############################################################################
# Require each lib file
#
class_files = File.join( File.dirname(__FILE__), 'torrentprocessor', '*.rb')
$: << File.join( File.dirname(__FILE__), 'torrentprocessor')  # Add directory to the include file array.
Dir.glob(class_files) do | class_file |
  #puts 'require ' + class_file[/\w+\.rb$/]
  require class_file[/\w+\.rb$/]
end

# If compiling with OCRA we want these gems available to us so we need
# to require them.
if defined? Ocra
  require 'pry'
  require 'rb-readline'
  require 'pry-nav'
  require 'pry-rescue'
  require 'pry-stack_explorer'
end

