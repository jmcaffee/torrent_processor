##############################################################################
# File::    controller.rb
# Purpose:: Main Controller object for TorrentProcessor utility
#
# Author::    Jeff McAffee 07/31/2011
# Copyright:: Copyright (c) 2011, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'ktcommon/ktpath'
require 'ktcommon/ktcmdline'


module TorrentProcessor

  ##########################################################################
  # Controller class
  class Controller

  attr_reader     :cfg
  attr_reader     :setup

    ###
    # Constructor
    #
    def initialize()
      tmp_setup = TPSetup.new({})
      if tmp_setup.config_needs_upgrade?
        tmp_setup.backup_config
        tmp_setup.upgrade_config(tmp_setup.app_data_path)
      end

      cfg_file_path = tmp_setup.cfg_path
      #File.join(TorrentProcessor.configuration.app_path, 'config.yml')
      TorrentProcessor.load_configuration(cfg_file_path)

      @cfg = TorrentProcessor.configuration

      init_services

      @setup = TPSetup.new(
        {
          :logger   => Runtime.service.logger,
          :database => Runtime.service.database
        }
      )
    end

    ###
    # User supplied a command line argument(s).
    # <em><b>Note:</b> that switches and options are not considered command line arguments.</em>
    #
    # returns:: False to indicate that the application should exit. False by default.
    #   <em><b>Note:</b> ArgumentError exception is raised as well.</em>
    #
    def process_cmd_line_args(arg)
      raise ArgumentError.new("Unexpected argument: #{arg}")
      return false    # Indicate that we have a problem - we are not expecting command line args.
    end

    ###
    # User supplied no command line arguments.
    # <em><b>Note:</b> Switches and options are not considered command line arguments.</em>
    #
    # returns:: True to indicate that the application should <b>NOT</b> exit. False by default.
    #
    def no_cmd_line_arg()
      #raise ArgumentError.new("Argument expected.")
      return true     # Indicate that we don't care if there is no command line arg.
    end


    ###
    # Tell user if setup needs to be completed, then process torrents.
    #
    def process()
      if !@setup.check_setup_completed()
        # Force the user to configure the application if it has not yet been configured.
        log "Torrent Processor has not yet been configured."
        log "Run Torrent Processor with the -init option to configure it."
        exit
      end

      Runtime.service.processor.process()
    end

    def init_services
      # Configure the default logger.
      FileLogger.logdir   = cfg.log_dir
      FileLogger.logfile  = 'tp-processing.log'
      Runtime.service.logger = FileLogger

      # Configure the database.
      Runtime.service.database = Database.new( :cfg => cfg )

      Runtime.service.webui_type = cfg.backend

      # Configure the backend interface
      if cfg.backend == :utorrent
        # Configure the uTorrent interface.
        Runtime.service.webui = Service::UTorrent::UTorrentWebUI.new(
                                                                cfg.utorrent.ip,
                                                                cfg.utorrent.port,
                                                                cfg.utorrent.user,
                                                                cfg.utorrent.pass )

      elsif cfg.backend == :qbtorrent
        # Configure the qBitTorrent interface.
        Runtime.service.webui = ::QbtClient::WebUI.new(
                                  cfg.qbtorrent.ip,
                                  cfg.qbtorrent.port,
                                  cfg.qbtorrent.user,
                                  cfg.qbtorrent.pass )
      end

      # Configure the MovieDB service.
      api_key = cfg.tmdb.api_key
      if api_key.nil? || api_key.empty?
        log "!!! No TMdb API key configured !!!"
        Runtime.service.moviedb = nil
      else
        Runtime.service.moviedb = Plugin::MovieDB.new( :api_key => cfg.tmdb.api_key,
                                                      :language => cfg.tmdb.language )
      end

      # Configure the processor (main object).
      Runtime.service.processor = Processor.new( :logger => Runtime.service.logger,
                                                 :webui => Runtime.service.webui,
                                                 :webui_type => Runtime.service.webui_type,
                                                 :database => Runtime.service.database,
                                                 :moviedb => Runtime.service.moviedb )

      # Configure the console object.
      Runtime.service.console = Console.new( :webui => Runtime.service.webui,
                                             :webui_type => Runtime.service.webui_type,
                                             :database => Runtime.service.database,
                                             :processor => Runtime.service.processor )
    end

    ###
    # Run Torrent Processor in interactive mode
    #
    def interactive_mode()
      if !@setup.check_setup_completed()
        # Tell the user to configure the application if it has not yet been configured.
        puts
        puts "*"*10
        puts "    Torrent Processor has not yet been configured."
        puts "    Use the .setup command from within the console or"
        puts "    run TorrentProcessor with the -init option to configure it."
        puts "*"*10
        puts
      end

      Runtime.service.console.execute
    end

    ###
    # Setup the application
    #
    def setup_app()
      @setup.setup_app()

    end

    def upgrade_database
      Runtime.service.database.upgrade
    end

    def upgrade_app
      if ! @setup.config_needs_upgrade?
        puts 'Configuration file is up to date. Skipping config upgrade.'
      else
        @setup.upgrade_config cfg.app_data
      end

      puts 'Attempting database upgrade'
      upgrade_database

      puts
      puts 'Finished.'
    end

    ###
    # Write message to torrentprocessor log
    #
    def log(msg)
      Runtime.service.logger.log msg
    end
  end # class Controller


end # module TorrentProcessor
