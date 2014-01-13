##############################################################################
# File::    console.rb
# Purpose:: Interactive console object for TorrentProcessor.
#
# Author::    Jeff McAffee 08/06/2011
# Copyright:: Copyright (c) 2011, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'ktcommon/ktpath'
require 'ktcommon/ktcmdline'
require_relative 'service/utorrent'
require 'formatter'
require 'plugin'
require_relative 'utility/loggers'


module TorrentProcessor

  ##########################################################################
  # Interactive Console class
  class Console

    include KtCmdLine
    include Plugin

  attr_reader     :controller
  attr_reader     :verbose
  attr_reader     :utorrent
  attr_reader     :database

    ###
    # Console constructor
    #
    def initialize(controller)
      $LOG.debug "Console::initialize"

      @controller = controller
      @verbose    = false
      @cmds       = Array.new
      @prompt     = "db>"
      Formatter.setOutputMode :pretty
      @qmode      = :db
      @rmode      = :body

      cfg         = @controller.cfg
      @utorrent   = TorrentProcessor::Service::UTorrent::UTorrentWebUI.new(cfg[:ip], cfg[:port], cfg[:user], cfg[:pass])
      @utorrent.verbose = false
      Runtime.configure do |service|
        service.utorrent = TorrentProcessor::Service::UTorrent::UTorrentWebUI.new(
          TorrentProcessor.configuration.utorrent.ip,
          TorrentProcessor.configuration.utorrent.port,
          TorrentProcessor.configuration.utorrent.user,
          TorrentProcessor.configuration.utorrent.pass )
        service.database = @controller.database
        service.moviedb = MovieDB.new(
          {:api_key => TorrentProcessor.configuration.tmdb.api_key,
           :language => TorrentProcessor.configuration.tmdb.language } )
        service.logger = ::ScreenLogger
      end

      @database   = @controller.database

      configure_commands
    end

    ###
    # Execute the console
    #
    def execute
      $LOG.debug "Console::execute"

      console_header
      console_help

      q = ""

      while q != ".quit"

        q = getInput(@prompt)
        if ( (q == ".quit") || (q == ".exit") )
          @database.close
          q = ".quit"
          next
        end

        if ( process_cmd(q) )
          next
        end

        begin
          result = (@qmode == :webui ? @utorrent.sendGetQuery(q) : @database.execute(q))
          if @qmode == :webui
            puts result if @rmode == :body
            if @rmode == :raw
              puts @utorrent.response.inspect
              puts @utorrent.response.body
            end
          end # qmode is webui

          if @qmode == :db
            Formatter.pHr
            puts "Query returned #{result.length} rows."
            Formatter.pHr
            Formatter.pQueryResults(result)
            #result.each do |r|
            # p r
            #end
          end # qmode is db

        rescue Exception => e
          puts e.message
          puts
          if @verbose
            puts "Exception type: #{e.class.to_s}"
            puts e.backtrace
            puts
          end
        end


      end # while q != .quit

      #utorrent.query("list")
    end

    ###
    # Process a command
    #
    # cmd:: cmd to process
    # returns:: true if command processed
    def process_cmd(cmd)
      $LOG.debug "Console::process_cmd( #{cmd} )"

      #result = CmdPluginManager.command(cmd, self)
      result = CmdPluginManager.command(cmd,
        {
          :cmd => cmd,
          :logger => Runtime.service.logger,
        })
      return result unless result.nil?

      cmd_parts = cmd.split
      if !@cmds.include?(cmd_parts[0])
        return false
      end

      return process_console_cmd( cmd )   if is_console_cmd?(cmd)

      return false
    end


  private

    def database
      Runtime.service.database
      # FIXME: replace @database with database
    end

    def utorrent
      Runtime.service.utorrent
      # FIXME: replace @utorrent with utorrent
    end

    def log msg = ''
      Runtime.service.logger.log msg
      # FIXME: replace puts with log
    end

    ###
    # Configure commands
    #
    def configure_commands
      $LOG.debug "Console::configure_commands"

      configure_console_commands
      configure_config_commands
      configure_db_commands
      configure_utorrent_commands
      configure_rss_commands
      configure_utility_commands
    end

    ###
    # Configure console specific commands
    #
    def configure_console_commands
      $LOG.debug "Console::configure_console_commands"

      @console_cmds = [
                        [".help", "Display this cmd help info"],
                        [".exit", "Exit Interactive Mode"],
                        [".quit", "Exit Interactive Mode"],
                        [".process", "Run normal processing tasks"],
                        [".qmode", "Toggle query mode (webui <=> db)"],
                        [".rmode", "Toggle request mode (BODY <=> RAW)"],
                        [".omode", "Toggle DB output mode (raw <=> pretty)"],
                        [".verbose", "Toggle verbose mode (on <=> off)"]
                      ]

      # Add the commands to a cmd array.
      @console_cmds.each do |c|
        @cmds << c[0]
      end
    end

    ###
    # Return true if given cmd is in console_cmds
    #
    # cmd:: commands to test for
    #
    def is_console_cmd?(cmd)
      $LOG.debug "Console::is_console_cmd?( #{cmd} )"

      cmd_parts = cmd.split
      return false unless !cmd_parts[0].nil?

      @console_cmds.each do |c|
        return true if c[0] == cmd_parts[0]
      end
      return false
    end

    ###
    # Configure TorrentProcessor Configuration specific commands
    #
    def configure_config_commands
      $LOG.debug "Console::configure_config_commands"

      CmdPluginManager.register_plugin(:cfg, CfgPlugin)
      @cfg_cmds = CmdPluginManager.command_list(:cfg)

      # Add the commands to a cmd array.
      @cfg_cmds.each do |c|
        @cmds << c[0]
      end
    end

    ###
    # Configure DB specific commands
    #
    def configure_db_commands
      $LOG.debug "Console::configure_db_commands"

      CmdPluginManager.register_plugin(:db, DBPlugin)
      @db_cmds = CmdPluginManager.command_list(:db)

      # Add the commands to a cmd array.
      @db_cmds.each do |c|
        @cmds << c[0]
      end
    end

    ###
    # Configure uTorrent specific commands
    #
    def configure_utorrent_commands
      $LOG.debug "Console::configure_utorrent_commands"

      CmdPluginManager.register_plugin(:ut, UTPlugin)
      @utorrent_cmds = CmdPluginManager.command_list(:ut)

      # Add the commands to a cmd array.
      @utorrent_cmds.each do |c|
        @cmds << c[0]
      end
    end

    ###
    # Configure uTorrent RSS specific commands
    #
    def configure_rss_commands
      $LOG.debug "Console::configure_rss_commands"

      CmdPluginManager.register_plugin(:rss, RSSPlugin)
      @rss_cmds = CmdPluginManager.command_list(:rss)

      # Add the commands to a cmd array.
      @rss_cmds.each do |c|
        @cmds << c[0]
      end
    end

    def configure_utility_commands
      CmdPluginManager.register_plugin(:util, Unrar)
      CmdPluginManager.register_plugin(:util, MovieDB)
      @util_cmds = CmdPluginManager.command_list :util

      # Add commands to cmd array.
      @util_cmds.each do |c|
        @cmds << c[0]
      end
    end

    ###
    # Set the verbose flag
    #
    # arg:: verbose mode if true
    #
    def verbose=(arg)
      $LOG.debug "Console::verbose=( #{arg} )"
      @verbose = arg
    end

    ###
    # Console header
    #
    def console_header
      hr = "="*79
      puts hr
      puts "Torrent Processer Interactive Console".center(79)
      puts hr
      puts
    end

    ###
    # Console help
    #
    def console_help
      $LOG.debug "Console::console_help"

      display_command_list( "Console Commands:", @console_cmds )
      display_command_list( "Configuration Commands:", @cfg_cmds )
      display_command_list( "DB Commands:", @db_cmds )
      display_command_list( "uTorrent Commands:", @utorrent_cmds )
      display_command_list( "RSS Commands:", @rss_cmds )
      display_command_list( "Utility Commands:", @util_cmds )

      puts
    end

    ###
    # Display a set of commands
    #
    def display_command_list( hdr, cmds )
      $LOG.debug "Console::display_command_list( #{hdr}, cmds )"

      puts
      hr = "-"*hdr.size
      puts "  #{hdr}"
      puts "  #{hr}"
      cmds.each do |c|
        o = "  #{c[0]}".ljust(22)
        o += c[1] unless c[1].nil?
        puts o
      end
    end

    ###
    # Process a console command
    #
    # cmd:: cmd to process
    # returns:: true if command processed
    def process_console_cmd(cmd)
      $LOG.debug "Console::process_console_cmd( #{cmd} )"

      cmd_parts = cmd.split

      if cmd == ".help"
        console_help
        return true
      end

      if cmd == ".process"
        @controller.process
        return true
      end

      if cmd == ".omode"
        Formatter.toggleOutputMode
        puts "Output Mode: #{Formatter.outputMode.to_s}"
        return true
      end

      if cmd == ".qmode"
        @qmode = (@qmode == :webui ? :db : :webui )
        @prompt = (@qmode == :webui ? "tp>" : "db>" )
        puts "Query Mode: #{@qmode.to_s}"
        return true
      end

      if cmd == ".rmode"
        @rmode = (@rmode == :body ? :raw : :body )
        puts "Request Mode: #{@rmode.to_s}"
        return true
      end

      if cmd == ".verbose"
        @verbose = (@verbose == true ? false : true )
        @utorrent.verbose = @verbose
        puts "Verbose Mode: #{@verbose.to_s}"
        return true
      end

      return false
    end

    ###
    # Process a DB command
    #
    # cmd:: cmd to process
    # returns:: true if command processed
    def process_db_cmd(cmd)
      $LOG.debug "Console::process_db_cmd( #{cmd} )"

      if cmd == ".db-insert"
        db_insert
        return true
      end

      return false
    end

    ###
    # Insert torrents into DB with data from torrents list
    #
    def db_insert
      $LOG.debug "Console::db_insert"

      data = @utorrent.getTorrentList
      puts "Torrents count: #{@utorrent.torrents.length.to_s}"
      torrents = @utorrent.torrents
      @database.connect
      torrents.each do |k,v|
        @database.create(v)
      end
    end
  end # class Console
end # module TorrentProcessor
