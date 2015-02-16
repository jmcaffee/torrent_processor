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
require_relative 'torrent_app'
require_relative 'utility/formatter'
require_relative 'plugin'
require_relative 'utility/loggers'


module TorrentProcessor

  ##########################################################################
  # Interactive Console class
  class Console

    include KtCmdLine
    include Plugin
    include Utility

  attr_reader :logger
  attr_reader :verbose
  attr_reader :torrent_app
  attr_reader :database
  attr_reader :processor

    ###
    # Console constructor
    #
    def initialize(args)
      parse_args args

      @cmds       = Array.new
      @prompt     = "db>"
      Formatter.set_output_mode :pretty
      @qmode      = :db
      @rmode      = :body

      configure_commands
    end

    def parse_args args
      args = defaults.merge(args)
      @init_args = args

      @logger     = args[:logger]     if args[:logger]
      @verbose    = args[:verbose]    if args[:verbose]
      @webui_type = args[:webui_type] if args[:webui_type]
      @webui      = args[:webui]      if args[:webui]
      @database   = args[:database]   if args[:database]
      @processor  = args[:processor]  if args[:processor]

      Formatter.logger = @logger
    end

    def defaults
      {
        :logger     => ::ScreenLogger,
        :verbose    => false
      }
    end

    def torrent_app
      @torrent_app ||= TorrentApp.new(@init_args)
    end

    ###
    # Execute the console
    #
    def execute
      console_header
      console_help

      q = ""

      while q != ".quit"

        q = getInput(@prompt)
        if ( (q == ".quit") || (q == ".exit") )
          database.close
          q = ".quit"
          next
        end

        if ( process_cmd(q) )
          next
        end

        begin
          result = nil
          elapsed = Benchmark.realtime do
            result = (@qmode == :webui ? torrent_app.send_get_query(q) : database.execute(q))
          end
          if @qmode == :webui
            log result if @rmode == :body
            if @rmode == :raw
              log torrent_app.response.inspect
              log torrent_app.response.body
            end
          end # qmode is webui

          if @qmode == :db
            Formatter.print_rule
            log "Query returned #{result.length} rows."
            Formatter.print_rule
            Formatter.print_query_results(result)
            #result.each do |r|
            # p r
            #end
          end # qmode is db

          log "[#{elapsed} sec]\n"

        rescue Exception => e
          log e.message
          log
          log "Exception type: #{e.class.to_s}"
          log e.backtrace
          log
        end


      end # while q != .quit
    end

    ###
    # Process a command
    #
    # cmd:: cmd to process
    # returns:: true if command processed
    def process_cmd(cmd)
      result = nil
      elapsed = Benchmark.realtime do
        result = CmdPluginManager.command(cmd,
          {
            :cmd        => cmd,
            :logger     => logger,
            :verbose    => verbose,
            :webui_type => @webui_type,
            :webui      => @webui,
            :database   => database,
          })
      end
      log "[#{elapsed} sec]" unless result.nil?
      return result unless result.nil?

      cmd_parts = cmd.split
      if !@cmds.include?(cmd_parts[0])
        return false
      end

      return process_console_cmd( cmd )   if is_console_cmd?(cmd)

      return false
    end


  private

    def log msg = ''
      @logger.log msg
    end

    ###
    # Configure commands
    #
    def configure_commands
      configure_console_commands
      configure_config_commands
      configure_db_commands
      configure_torrent_commands
      configure_rss_commands
      configure_utility_commands
    end

    ###
    # Configure console specific commands
    #
    def configure_console_commands
      @console_cmds = [
                        [".help", "Display this cmd help info"],
                        [".exit", "Exit Interactive Mode"],
                        [".quit", "Exit Interactive Mode"],
                        [".setup", "Configure application"],
                        [".process", "Run normal processing tasks"],
                        [".qmode", "Toggle query mode (webui <=> db)"],
                        [".rmode", "Toggle request mode (BODY <=> RAW)"],
                        [".omode", "Toggle DB output mode (raw <=> pretty)"],
                        [".verbose", "Verbose output"],
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
      CmdPluginManager.register_plugin(:db, DBPlugin)
      @db_cmds = CmdPluginManager.command_list(:db)

      # Add the commands to a cmd array.
      @db_cmds.each do |c|
        @cmds << c[0]
      end
    end

    ###
    # Configure Torrent specific commands
    #
    def configure_torrent_commands
      CmdPluginManager.register_plugin(:ut, UTPlugin)
      @torrent_cmds = CmdPluginManager.command_list(:ut)

      # Add the commands to a cmd array.
      @torrent_cmds.each do |c|
        @cmds << c[0]
      end
    end

    ###
    # Configure Torrent RSS specific commands
    #
    def configure_rss_commands
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
    # Console header
    #
    def console_header
      hr = "="*79
      log hr
      log "Torrent Processer Interactive Console".center(79)
      log hr
      log
    end

    ###
    # Console help
    #
    def console_help
      display_command_list( "Console Commands:", @console_cmds )
      display_command_list( "Configuration Commands:", @cfg_cmds )
      display_command_list( "DB Commands:", @db_cmds )
      display_command_list( "Torrent Commands:", @torrent_cmds )
      display_command_list( "RSS Commands:", @rss_cmds )
      display_command_list( "Utility Commands:", @util_cmds )

      log
    end

    ###
    # Display a set of commands
    #
    def display_command_list( hdr, cmds )
      log
      hr = "-"*hdr.size
      log "  #{hdr}"
      log "  #{hr}"
      cmds.each do |c|
        o = "  #{c[0]}".ljust(22)
        o += c[1] unless c[1].nil?
        log o
      end
    end

    ###
    # Process a console command
    #
    # cmd:: cmd to process
    # returns:: true if command processed
    def process_console_cmd(cmd)
      cmd_parts = cmd.split

      if cmd == ".help"
        console_help
        return true
      end

      if cmd == ".process"
        processor.process
        return true
      end

      if cmd == ".omode"
        Formatter.toggle_output_mode
        log "Output Mode: #{Formatter.output_mode.to_s}"
        return true
      end

      if cmd == ".qmode"
        @qmode = (@qmode == :webui ? :db : :webui )
        @prompt = (@qmode == :webui ? "tp>" : "db>" )
        log "Query Mode: #{@qmode.to_s}"
        return true
      end

      if cmd == ".rmode"
        @rmode = (@rmode == :body ? :raw : :body )
        log "Request Mode: #{@rmode.to_s}"
        return true
      end

      if cmd == ".setup"
        log ".setup is not implemented yet. Restart app with --init option."
        return true
      end

      if cmd == ".verbose"
        @verbose = !verbose
        update_plugins_verbose_mode verbose
        log "Verbose Mode: #{verbose.to_s}"
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
      data = torrent_app.getTorrentList
      log "Torrents count: #{torrent_app.torrents.length.to_s}"
      torrents = torrent_app.torrents
      database.connect
      torrents.each do |k,v|
        database.create(v)
      end
    end

    ###
    # Set plugins verbose mode
    #

    def update_plugins_verbose_mode flag
      @torrent_app.verbose  = flag
      @database.verbose     = flag
      @database.logger      = logger
      @processor.verbose    = flag
    end
  end # class Console
end # module TorrentProcessor
