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

  attr_reader     :aswitch
  attr_accessor   :model
  attr_reader     :verbose
  attr_reader     :cfg
  attr_reader     :setup
  attr_reader     :database

    ###
    # Constructor
    #
    def initialize()
      $LOG.debug "Controller::initialize"
      @cfg            = Config.new.load
      @model          = Processor.new(self)
      @setup          = TPSetup.new(self)
      @database       = Database.new(self)
      @model.verbose  = false
      @aswitch        = false
      @logfile        = "tp-processing.log"
    end


    ###
    # Set the srcdir. The value is actually maintained/stored in the model.
    # srcdirpath:: input file directory path
    # returns:: previous srcdir
    #
    def srcdir(srcdirpath)
      $LOG.debug "Controller::srcdir( #{srcdirpath} )"
      ret = @model.srcdir
      @model.srcdir = srcdirpath
      ret
    end


    ###
    # Assignment operator for setting the srcdir.
    # srcdirpath:: input file directory path
    # returns:: previous srcdir
    #
    def srcdir=(srcdirpath)
      $LOG.debug "Controller::srcdir=( #{srcdirpath} )"
      return srcdir(srcdirpath)
    end


    ###
    # Set the srcfile. The value is actually maintained/stored in the model.
    # srcfilepath:: source file path
    # returns:: previous srcfile
    #
    def srcfile(srcfilepath)
      $LOG.debug "Controller::srcfile( #{srcfilepath} )"
      ret = @model.srcfile
      @model.srcfile = srcfilepath
      ret
    end


    ###
    # Assignment operator for setting the srcfile.
    # srcfilepath:: source file path
    # returns:: previous srcfile
    #
    def srcfile=(srcfilepath)
      $LOG.debug "Controller::srcfile=( #{srcfilepath} )"
      return srcfile(srcfilepath)
    end


    ###
    # Set the torrent state. The value is actually maintained/stored in the model.
    # state:: current torrent state
    # returns:: previous 'current' torrent state
    #
    def state(stateval)
      $LOG.debug "Controller::state( #{stateval} )"
      ret = @model.state
      @model.state = stateval
      ret
    end


    ###
    # Assignment operator for setting the state.
    # state:: current torrent state
    # returns:: previous 'current' torrent state
    #
    def state=(stateval)
      $LOG.debug "Controller::state=( #{stateval} )"
      return state(stateval)
    end


    ###
    # Set the torrent's prevstate. The value is actually maintained/stored in the model.
    # stateval:: previous torrent state
    # returns:: previous 'previous' torrent state
    #
    def prevstate(stateval)
      $LOG.debug "Controller::prevstate( #{stateval} )"
      ret = @model.prevstate
      @model.prevstate = stateval
      ret
    end


    ###
    # Assignment operator for setting the previous state.
    # stateval:: previous torrent state
    # returns:: previous 'previous' torrent state
    #
    def prevstate=(stateval)
      $LOG.debug "Controller::prevstate=( #{stateval} )"
      return prevstate(stateval)
    end


    ###
    # Set the torrent's msg. The value is actually maintained/stored in the model.
    # msgval:: msg value from uTorrent
    # returns:: previous msg value
    #
    def msg(msgval)
      $LOG.debug "Controller::msg( #{msgval} )"
      ret = @model.msg
      @model.msg = msgval
      ret
    end


    ###
    # Assignment operator for setting the uTorrent msg.
    # msgval:: msg value from uTorrent
    # returns:: previous msg value
    #
    def msg=(msgval)
      $LOG.debug "Controller::msg=( #{msgval} )"
      return msg(msgval)
    end


    ###
    # Set the torrent's label. The value is actually maintained/stored in the model.
    # labelval:: label value from uTorrent
    # returns:: previous label value
    #
    def label(labelval)
      $LOG.debug "Controller::label( #{labelval} )"
      ret = @model.label
      @model.label = labelval
      ret
    end


    ###
    # Assignment operator for setting the uTorrent label.
    # labelval:: label value from uTorrent
    # returns:: previous label value
    #
    def label=(labelval)
      $LOG.debug "Controller::label=( #{labelval} )"
      return label(labelval)
    end


    ###
    # Set the verbose flag. The flag is actually maintained/stored in the model.
    # arg:: True = verbose on
    #
    def verbose(arg)
      $LOG.debug "Controller::verbose( #{arg} )"
      puts "Verbose mode: #{arg.to_s}" if @verbose
      @model.verbose = arg
      @setup.verbose = arg
    end


    ###
    # Assignment operator for setting the verbose flag.
    # arg:: True = verbose on
    #
    def verbose=(arg)
      $LOG.debug "Controller::verbose=( #{arg} )"
      return verbose(arg)
    end


    ###
    # Write the default config file to disk
    #
    #
    #
    def writeCfg()
      $LOG.debug "Controller::writeCfg()"
      Config.new.save
    end


    ###
    # User supplied a command line argument(s).
    # <em><b>Note:</b> that switches and options are not considered command line arguments.</em>
    #
    # returns:: False to indicate that the application should exit. False by default.
    #   <em><b>Note:</b> ArgumentError exception is raised as well.</em>
    #
    def processCmdLineArgs(arg)
      $LOG.debug "Controller::processCmdLineArgs( #{arg} )"
      raise ArgumentError.new("Unexpected argument: #{arg}")
      return false    # Indicate that we have a problem - we are not expecting command line args.
    end


    ###
    # User supplied no command line arguments.
    # <em><b>Note:</b> Switches and options are not considered command line arguments.</em>
    #
    # returns:: True to indicate that the application should <b>NOT</b> exit. False by default.
    #
    def noCmdLineArg()
      $LOG.debug "Controller::noCmdLineArg"
      #raise ArgumentError.new("Argument expected.")
      return true     # Indicate that we don't care if there is no command line arg.
    end


    ###
    # TODO: write process() description
    #
    def process()
      $LOG.debug "Controller::process"

      checkSetupCompleted()

      @model.process()
    end


    ###
    # Run Torrent Processor in interactive mode
    #
    def interactiveMode()
      $LOG.debug "Controller::interactiveMode"

      if !@setup.checkSetupCompleted()
        # Tell the user to configure the application if it has not yet been configured.
        puts
        puts "*"*10
        puts "    Torrent Processor has not yet been configured."
        puts "    Use the .setup command from within the console or"
        puts "    run TorrentProcessor with the -init option to configure it."
        puts "*"*10
        puts
      end
      @model.interactiveMode()
    end


    ###
    # Check to make sure the user has setup the application
    #
    def checkSetupCompleted()
      $LOG.debug "Controller::checkSetupCompleted"
      if !@setup.checkSetupCompleted()
        # Force the user to configure the application if it has not yet been configured.
        puts "Torrent Processor has not yet been configured."
        puts "Run Torrent Processor with the -init option to configure it."
        exit
      end

    end


    ###
    # Setup the application
    #
    def setupApp()
      $LOG.debug "Controller::setupApp"
      @setup.setupApp()

    end

    def upgradeDb
      # FIXME: Support upgrading the DB
    end

    ###
    # Write message to torrentprocessor log
    #
    def log(msg)
      $LOG.debug "Controller::log( msg )"
      logfile = File.join( @cfg[:logdir], @logfile )
      timestamp = DateTime.now.strftime()

      File.open( logfile, 'a' ) {|f| f.write( "#{timestamp}:  #{msg}\n" ); f.flush; }

    end


    ###
    # Rotate torrentprocessor logs
    #
    def rotate_logs()
      $LOG.debug "Controller::rotate_logs()"
      max_size = @cfg[:maxlogsize]
      return if max_size == 0

      logfile = File.join( @cfg[:logdir], @logfile )

      if (File.new( logfile ).size > max_size)
        FileUtils.rm( "#{logfile}.3" ) if File.exists?( "#{logfile}.3" )
        FileUtils.mv( "#{logfile}.2", "#{logfile}.3" ) if File.exists?( "#{logfile}.2" )
        FileUtils.mv( "#{logfile}.1", "#{logfile}.2" ) if File.exists?( "#{logfile}.1" )
        FileUtils.mv( "#{logfile}", "#{logfile}.1" ) if File.exists?( "#{logfile}" )
      end

    end


    ###
    # Add a tracker seedlimit filter to the config file
    #
    def add_filter(tracker, seedlimit)
      $LOG.debug "Controller::add_filter( #{tracker}, #{seedlimit} )"

      filters = @cfg[:filters]
      filters = {} if filters.nil?
      filters[tracker] = seedlimit
      @cfg[:filters] = filters
      c = Config.new
      c.cfg = @cfg
      c.save

    end


    ###
    # Remove a tracker seedlimit filter from the config file
    #
    def delete_filter(tracker)
      $LOG.debug "Controller::delete_filter( #{tracker} )"
      filters = @cfg[:filters]
      return if filters.nil?
      return if (! filters.include?( tracker ) )
      filters.delete( tracker )
      @cfg[:filters] = filters
      c = Config.new
      c.cfg = @cfg
      c.save
    end


    ###
    # Set the uTorrent WebUI username
    #
    def set_user(user)
      $LOG.debug "Controller::set_user( #{user} )"

      @cfg[:user] = user
      c = Config.new
      c.cfg = @cfg
      c.save

    end


    ###
    # Set the uTorrent WebUI password
    #
    def set_pwd(pwd)
      $LOG.debug "Controller::set_pwd( #{pwd} )"

      @cfg[:pass] = pwd
      c = Config.new
      c.cfg = @cfg
      c.save

    end


    ###
    # Set the uTorrent IP address
    #
    def set_ip(ip)
      $LOG.debug "Controller::set_ip( #{ip} )"

      @cfg[:ip] = ip
      c = Config.new
      c.cfg = @cfg
      c.save

    end


    ###
    # Set the uTorrent Port number
    #
    def set_port(port)
      $LOG.debug "Controller::set_port( #{port} )"

      @cfg[:port] = port
      c = Config.new
      c.cfg = @cfg
      c.save

    end


  end # class Controller


end # module TorrentProcessor
