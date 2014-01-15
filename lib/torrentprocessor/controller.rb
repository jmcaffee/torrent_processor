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

  attr_accessor   :model
  attr_reader     :verbose
  attr_reader     :cfg
  attr_reader     :setup

    ###
    # Constructor
    #
    def initialize()
      @cfg            = TorrentProcessor.configuration
      @model          = Processor.new(self)
      @model.verbose  = false

      FileLogger.logdir   = @cfg.log_dir
      FileLogger.logfile  = 'tp-processing.log'

      Runtime.service.logger    = FileLogger
      Runtime.service.database  = Database.new( :cfg => @cfg )

      @setup = TPSetup.new(
        {
          :logger   => Runtime.service.logger,
          :database => Runtime.service.database
        }
      )
    end

    ###
    # Set the verbose flag. The flag is actually maintained/stored in the model.
    # arg:: True = verbose on
    #
    def verbose(arg)
      # FIXME: Replace 'puts' with 'log'
      puts "Verbose mode: #{arg.to_s}" if @verbose
      @model.verbose = arg
      @setup.verbose = arg
    end

    ###
    # Assignment operator for setting the verbose flag.
    # arg:: True = verbose on
    #
    def verbose=(arg)
      return verbose(arg)
    end

    ###
    # Write the default config file to disk
    #
    #
    #
    def writeCfg()
      Config.new.save
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
    # TODO: write process() description
    #
    def process()
      if !@setup.check_setup_completed()
        # Force the user to configure the application if it has not yet been configured.
        puts "Torrent Processor has not yet been configured."
        puts "Run Torrent Processor with the -init option to configure it."
        exit
      end

      @model.process()
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
      @model.interactive_mode()
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
        @setup.upgrade_config @cfg[:appData]
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
      FileLogger.log msg
    end
  end # class Controller


end # module TorrentProcessor
