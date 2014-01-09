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
require 'utorrentwebui'
require 'formatter'
require 'plugin'
require 'plugin/db_plugin'
require 'plugin/ut_plugin'
require 'plugin/cfg_plugin'
require_relative 'console_plugin'


module TorrentProcessor

  ##########################################################################
  # Interactive Console class
  class Console

    include KtCmdLine
    include Plugin
    include ConsolePlugin

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
      @utorrent   = UTorrentWebUI.new(cfg[:ip], cfg[:port], cfg[:user], cfg[:pass])
      @utorrent.verbose = false

      @database   = @controller.database

      configureCommands()
    end


    ###
    # Configure commands
    #
    def configureCommands()
      $LOG.debug "Console::configureCommands()"

      configureConsoleCommands()
      configureConfigCommands()
      configureDbCommands()
      configureUTorrentCommands()
      configureRSSCommands()
      configure_utility_commands()
    end


    ###
    # Configure console specific commands
    #
    def configureConsoleCommands()
      $LOG.debug "Console::configureConsoleCommands()"

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
    def configureConfigCommands()
      $LOG.debug "Console::configureConfigCommands()"

      PluginManager.register_plugin(:cfg, CfgPlugin)
      @cfg_cmds = PluginManager.command_list(:cfg)

      # Add the commands to a cmd array.
      @cfg_cmds.each do |c|
        @cmds << c[0]
      end
    end


    ###
    # Configure DB specific commands
    #
    def configureDbCommands()
      $LOG.debug "Console::configureDbCommands()"

      PluginManager.register_plugin(:db, DBPlugin)
      @db_cmds = PluginManager.command_list(:db)

      # Add the commands to a cmd array.
      @db_cmds.each do |c|
        @cmds << c[0]
      end
    end


    ###
    # Configure uTorrent specific commands
    #
    def configureUTorrentCommands()
      $LOG.debug "Console::configureUTorrentCommands()"

      PluginManager.register_plugin(:ut, UTPlugin)
      @utorrent_cmds = PluginManager.command_list(:ut)

      # Add the commands to a cmd array.
      @utorrent_cmds.each do |c|
        @cmds << c[0]
      end
    end


    ###
    # Configure uTorrent RSS specific commands
    #
    def configureRSSCommands()
      $LOG.debug "Console::configureRSSCommands()"

      PluginManager.register_plugin(:rss, RSSPlugin)
      @rss_cmds = PluginManager.command_list(:rss)

      # Add the commands to a cmd array.
      @rss_cmds.each do |c|
        @cmds << c[0]
      end
    end

    def configure_utility_commands
      PluginManager.register_plugin(:util, UnrarPlugin)
      PluginManager.register_plugin(:util, MovieDB)
      @util_cmds = PluginManager.command_list :util

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
    def consoleHeader()
      hr = "="*79
      puts hr
      puts "Torrent Processer Interactive Console".center(79)
      puts hr
      puts
    end


    ###
    # Console help
    #
    def consoleHelp()
      $LOG.debug "Console::consoleHelp()"

      displayCommandList( "Console Commands:", @console_cmds )
      displayCommandList( "Configuration Commands:", @cfg_cmds )
      displayCommandList( "DB Commands:", @db_cmds )
      displayCommandList( "uTorrent Commands:", @utorrent_cmds )
      displayCommandList( "RSS Commands:", @rss_cmds )
      displayCommandList( "Utility Commands:", @util_cmds )

      puts
    end


    ###
    # Display a set of commands
    #
    def displayCommandList( hdr, cmds )
      $LOG.debug "Console::displayCommandList( #{hdr}, cmds )"

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
    # Process a command
    #
    # cmd:: cmd to process
    # returns:: true if command processed
    def processCmd(cmd)
      $LOG.debug "Console::processCmd( #{cmd} )"

      result = PluginManager.command(cmd, self)
      return result unless result.nil?

      cmd_parts = cmd.split
      if !@cmds.include?(cmd_parts[0])
        return false
      end

      return processConsoleCmd( cmd )   if is_console_cmd?(cmd)

      return false

    end


    ###
    # Process a console command
    #
    # cmd:: cmd to process
    # returns:: true if command processed
    def processConsoleCmd(cmd)
      $LOG.debug "Console::processConsoleCmd( #{cmd} )"

      cmd_parts = cmd.split

      if cmd == ".help"
        consoleHelp()
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
    def processDbCmd(cmd)
      $LOG.debug "Console::processDbCmd( #{cmd} )"

      if cmd == ".db-insert"
        dbInsert()
        return true
      end

      return false
    end


    ###
    # Insert torrents into DB with data from torrents list
    #
    def dbInsert()
      $LOG.debug "Console::dbInsert"

      data = @utorrent.getTorrentList()
      puts "Torrents count: #{@utorrent.torrents.length.to_s}"
      torrents = @utorrent.torrents
      @database.connect()
      torrents.each do |k,v|
        @database.create(v)
      end

    end


    ###
    # Execute the console
    #
    def execute()
      $LOG.debug "Console::execute"

      consoleHeader()
      consoleHelp()

      q = ""

      while q != ".quit"

        q = getInput(@prompt)
        if ( (q == ".quit") || (q == ".exit") )
          @database.close
          q = ".quit"
          next
        end

        if ( processCmd(q) )
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
  end # class Console
end # module TorrentProcessor
