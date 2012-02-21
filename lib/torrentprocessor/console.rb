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


module TorrentProcessor
    
  ##########################################################################
  # Interactive Console class
  class Console
  
    include KtCmdLine

  attr_reader     :controller
  attr_reader     :verbose
    
    ###
    # Console constructor
    #
    def initialize(controller)
      $LOG.debug "Console::initialize"
      
      @controller = controller
      @verbose    = true
      @cmds       = Array.new
      @prompt     = "db>"
      @omode      = :pretty
      @qmode      = :db
      @rmode      = :body
      
      cfg         = @controller.cfg
      @utorrent   = UTorrentWebUI.new(cfg[:ip], cfg[:port], cfg[:user], cfg[:pass])
      @utorrent.verbose = true
      
      @database   = @controller.database
      
      @hr         = "-"*40
      
      configureCommands()
    end
    

    ###
    # Configure commands
    #
    def configureCommands()
      $LOG.debug "Console::configureCommands()"
    
      configureConsoleCommands()
      configureDbCommands()
      configureUTorrentCommands()
    end
    
    
    ###
    # Configure console specific commands
    #
    def configureConsoleCommands()
      $LOG.debug "Console::configureConsoleCommands()"
    
      @console_cmds = [
                        [".exit", "Exit Interactive Mode"],
                        [".help", "Display this cmd help info"],
                        [".omode", "Toggle DB output mode (raw <=> pretty)"],
                        [".process", "Run normal processing tasks"],
                        [".qmode", "Toggle query mode (webui <=> db)"],
                        [".quit", "Exit Interactive Mode"],
                        [".ratios", "Display torrent ratios (in DB)"],
                        [".rmode", "Toggle request mode (BODY <=> RAW)"],
                        [".schema", "Display the table CREATE statements. Use .schema ?TABLE? for individual tables."],
                        [".setup", "Configure TorrentProcessor"],
                        [".cfg.addfilter", "Add a tracker seed filter"],
                        [".cfg.delfilter", "Delete a tracker seed filter"],
                        [".cfg.listfilters", "List current tracker filters"],
                        [".status", "Display status of torrents (in DB)"],
                        [".tables", "Display list of tables (in DB)"],
                        [".update-state", "Update a torrent's state"],
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
    # Configure DB specific commands
    #
    def configureDbCommands()
      $LOG.debug "Console::configureDbCommands()"

      @db_cmds = [
                    [".db-aquire-lock", "Lock the DB"],
                    [".db-close", "Close the TorrentProcessor DB connection"],
                    [".db-connect", "Connect to TorrentProcessor DB"],
                    [".db-insert", "Insert torrents into DB using torrent data"],
                    [".db-read-lock", "Read the current app lock value"],
                    [".db-release-lock", "Release the DB lock"],
                    [".db-set-lock", "Set the current app lock value"],
                    [".db-update", "Clear out DB and update with fresh torrent data"]
                  ]
                      
      # Add the commands to a cmd array.
      @db_cmds.each do |c|
        @cmds << c[0]
      end
    end
    
    
    ###
    # Return true if given cmd is in db_cmds
    #
    # cmd:: commands to test for
    #
    def is_db_cmd?(cmd)
      $LOG.debug "Console::is_db_cmd?( #{cmd} )"
    
      cmd_parts = cmd.split
      return false unless !cmd_parts[0].nil?
      
      @db_cmds.each do |c|
        return true if c[0] == cmd_parts[0]
      end
      return false
    end
    
    
    ###
    # Configure uTorrent specific commands
    #
    def configureUTorrentCommands()
      $LOG.debug "Console::configureUTorrentCommands()"

      @utorrent_cmds =  [
                          [".ut-data", "Dump collected torrent data"],
                          [".ut-list", "Get a list of torrents"],
                          [".ut-names", "Dump collected torrent names"],
                          [".ut-parse", "Parse response body"],
                          [".ut-settings", "Retrieve uTorrent settings"],
                          [".ut-test", "Test webui connection"],
                          [".ut-jobprops", "Retrieve a torrent's job properties"],
                          ["-gettorrentlist", ""]
                        ]
      # Add the commands to a cmd array.
      @utorrent_cmds.each do |c|
        @cmds << c[0]
      end
    end
    
    
    ###
    # Return true if given cmd is in utorrent_cmds
    #
    # cmd:: commands to test for
    #
    def is_utorrent_cmd?(cmd)
      $LOG.debug "Console::is_utorrent_cmd?( #{cmd} )"
    
      cmd_parts = cmd.split
      return false unless !cmd_parts[0].nil?
      
      @utorrent_cmds.each do |c|
        return true if c[0] == cmd_parts[0]
      end
      return false
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
      puts
      t = "Console Commands:"
      hr = "-"*t.size
      puts "  #{t}"
      puts "  #{hr}"
      @console_cmds.each do |c|
        o = "  #{c[0]}".ljust(22)
        o += c[1] unless c[1].nil?
        puts o
      end
      
      puts
      t = "DB Commands:"
      hr = "-"*t.size
      puts "  #{t}"
      puts "  #{hr}"
      @db_cmds.each do |c|
        o = "  #{c[0]}".ljust(22)
        o += c[1] unless c[1].nil?
        puts o
      end
      
      puts
      t = "uTorrent Commands:"
      hr = "-"*t.size
      puts "  #{t}"
      puts "  #{hr}"
      @utorrent_cmds.each do |c|
        o = "  #{c[0]}".ljust(22)
        o += c[1] unless c[1].nil?
        puts o
      end
      
      puts
    end
    
    
    ###
    # Process a command
    #
    # cmd:: cmd to process
    # returns:: true if command processed
    def processCmd(cmd)
      $LOG.debug "Console::processCmd( #{cmd} )"
      
      cmd_parts = cmd.split
      if !@cmds.include?(cmd_parts[0])
        return false
      end
      
      return processConsoleCmd( cmd )   if is_console_cmd?(cmd)
      return processDbCmd( cmd )        if is_db_cmd?(cmd)
      return processUTorrentCmd( cmd )  if is_utorrent_cmd?(cmd)
      
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
        @omode = (@omode == :raw ? :pretty : :raw )
        puts "Output Mode: #{@omode.to_s}"
        return true
      end
      
      if cmd == ".qmode"
        @qmode = (@qmode == :webui ? :db : :webui )
        @prompt = (@qmode == :webui ? "tp>" : "db>" )
        puts "Query Mode: #{@qmode.to_s}"
        return true
      end
      
      if cmd == ".ratios"
        putsHeader "ID | Ratio | Name"
        q = "SELECT id,ratio,name from torrents;"
        outputQueryResults( @database.execute( q ) )
        return true
      end
      
      if cmd == ".rmode"
        @rmode = (@rmode == :body ? :raw : :body )
        puts "Request Mode: #{@rmode.to_s}"
        return true
      end
      
      if cmd == ".update-state"
        update_torrent_state()
        return true
      end
      
      if cmd_parts[0] == ".schema"
        if !cmd_parts[1].nil?
          q = "SELECT sql FROM sqlite_master WHERE name=\"#{cmd_parts[1]}\";"
        else
          q = "SELECT sql FROM sqlite_master;"
        end
        
        putsHeader "Table description(s)"
        outputQueryResults( @database.execute( q ) )
        return true;
      end
      
      if cmd == ".status"
        putsHeader "ID | TP State | Name"
        q = "SELECT id,tp_state,name from torrents;"
        outputQueryResults( @database.execute( q ) )
        return true
      end
      
      if cmd == ".tables"
        putsHeader "Tables in DB"
        q = "SELECT name from sqlite_master WHERE type = 'table' ORDER BY name;"
        outputQueryResults( @database.execute( q ) )
        return true
      end
      
      if cmd == ".verbose"
        @verbose = (@verbose == true ? false : true )
        @utorrent.verbose = @verbose
        puts "Verbose Mode: #{@verbose.to_s}"
        return true
      end
      
      if cmd == ".setup"
        setupApp()
        return true
      end
      
      if cmd == ".cfg.addfilter"
        cfg_AddFilter()
        return true
      end

      if cmd == ".cfg.delfilter"
        cfg_DeleteFilter()
        return true
      end
      
      if cmd == ".cfg.listfilters"
        cfg_ListFilters()
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

      if cmd == ".db-aquire-lock"
        result = @database.aquire_lock
        puts "Lock aquired: #{result.to_s}"
        return true
      end
      
      if cmd == ".db-close"
        @database.close()
        return true
      end
      
      if cmd == ".db-connect"
        @database.connect()
        return true
      end
      
      if cmd == ".db-insert"
        dbInsert()
        return true
      end
      
      if cmd == ".db-read-lock"
        puts @database.read_lock()
        return true
      end
      
      if cmd == ".db-release-lock"
        result = @database.release_lock
        puts "Lock released: #{result.to_s}"
        return true
      end
      
      if cmd == ".db-set-lock"
        dbSetLock()
        return true
      end
      
      if cmd == ".db-update"
        dbUpdate()
        return true
      end
      
      return false
    end

    
    ###
    # Process a uTorrent command
    #
    # cmd:: cmd to process
    # returns:: true if command processed
    def processUTorrentCmd(cmd)
      $LOG.debug "Console::processUTorrentCmd( #{cmd} )"

      cmd_parts = cmd.split
      
      if cmd == ".ut-data"
        len = @utorrent.torrents.length
        if len == 0
          puts "No torrents to dump"
          return true
        end
        
        puts @hr
        puts "Torrent Dump"
        puts @hr
        puts
        
        @utorrent.torrents.each do |t|
          puts t.inspect
          puts
          puts @hr
          puts
        end
        
        return true
      end
      
      if cmd == ".ut-names"
        len = @utorrent.torrents.length
        if len == 0
          puts "No torrents to dump"
          return true
        end
        
        puts @hr
        puts "Torrent Names"
        puts @hr
        puts
        
        @utorrent.torrents.each do |k,v|
          puts "...#{k.slice(-4,4)}\t#{v.name}"
        end
        
        puts
        puts @hr
        puts
        
        return true
      end
      
      if cmd == ".ut-list"
        data = @utorrent.sendGetQuery("/gui/?list=1")
        puts data if @verbose
        return true
      end
      
      if cmd == ".ut-parse"
        response = @utorrent.parseResponse()
        puts response.inspect if @verbose
        return true
      end
      
      if cmd == ".ut-settings"
        @utorrent.get_utorrent_settings()
        response = @utorrent.parseResponse()
        puts response.inspect if @verbose
        puts @hr
        puts "uTorrent Settings"
        puts @hr
        puts
        #puts @utorrent.settings.class
        @utorrent.settings.each do |i|
          #puts @utorrent.settings.inspect
          puts i.inspect
        end
        return true
      end
      
      if cmd_parts[0] == ".ut-jobprops"
        puts "usage: .ut-jobprops #" if cmd_parts.length == 1
        puts "  # - either the DB id of torrent to retrieve props for or zero for all torrents." if cmd_parts.length == 1
        return true if cmd_parts.length == 1
        
        puts "Retrieving Job Properties"
        dump_jobprops( cmd_parts[1] )
        return true
      end

      if cmd == "-gettorrentlist"
        data = @utorrent.get_torrent_list()
        puts data if @verbose
        puts "Torrents count: #{@utorrent.torrents.length.to_s}"
        return true
      end
      
      if cmd == ".ut-test"
        testConnection()
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
    # Set application lock value
    #
    def dbSetLock()
      $LOG.debug "Console::dbSetLock"
      
      val = getInput("Value to set lock to (Y/N): ")
      puts "Invalid value." if val != "Y" && val != "N"
      return if val != "Y" && val != "N"
      
      @database.update_lock(val)
    end
      
    
    ###
    # Update DB with data from torrents list
    #
    def dbUpdate()
      $LOG.debug "Console::dbUpdate"
      
      puts "Not Implemented yet."
      
      # Remove all torrents in DB.
      q = "SELECT hash FROM torrents;"
      rows = @database.execute(q)
      
      # For each torrent in list, remove it
      rows.each do |r|
        @database.delete_torrent( r[0] )
      end

      # Get a list of torrents.
      cacheID = @database.read_cache()
      @utorrent.get_torrent_list( cacheID )
      @database.update_cache( @utorrent.cache )
      
      # Update the db's list of torrents.
      @database.update_torrents( @utorrent.torrents )
      
    end
      
    
    ###
    # Request application configuration setup
    #
    def setupApp()
      $LOG.debug "Console::setupApp"
      
      @controller.setupApp()
    end
      
    
    ###
    # Add a tracker seed filter
    #
    def cfg_AddFilter()
      $LOG.debug "Console::cfg_AddFilter"

      tracker = getInput( " trackers contains:" )
      seedval = getInput( " set seed limit to: " )
      
      if tracker.empty? || seedval.empty?
        puts "Add filter cancelled (invalid input)."
        return
      end

      @controller.add_filter( tracker, seedval )
      puts "Filter added for #{tracker} with a seed limit of #{seedval}"
    end


    ###
    # Remove a tracker seed filter
    #
    def cfg_DeleteFilter()
      $LOG.debug "Console::cfg_DeleteFilter"

      cfg_ListFilters()
      puts
      tracker = getInput( " tracker:" )
      
      if tracker.empty?
        puts "Delete filter cancelled (invalid input)."
        return
      end

      @controller.delete_filter( tracker )
      puts "Filter removed for #{tracker}"
    end


    ###
    # List all tracker seed filters
    #
    def cfg_ListFilters()
      $LOG.debug "Console::cfg_ListFilters"

      puts "Current Filters:"
      puts "----------------"
      filters = @controller.cfg[:filters]
      puts " None" if (filters.nil? || filters.length < 1)
      return if (filters.nil? || filters.length < 1)
      
      filters.each do |tracker, seedlimit|
        puts " #{tracker} : #{seedlimit}"
      end
    end


    ###
    # Test the webui connection
    #
    def testConnection()
      $LOG.debug "Console::testConnection"
      
      puts "Attempting to connect to #{@controller.cfg[:ip]}:#{@controller.cfg[:port]} using login #{@controller.cfg[:user]}/#{@controller.cfg[:pass]}"
      
      begin
        @utorrent = UTorrentWebUI.new(@controller.cfg[:ip], @controller.cfg[:port], @controller.cfg[:user], @controller.cfg[:pass])
        @utorrent.sendGetQuery("/gui/?list=1")
        
      rescue Exception => e
        puts
        puts "* Connection attempt has failed with the following reason:"
        puts
        puts e.message
        puts
        return false
      end
      
      puts "Connected successfully!"
      return true
    end
      
    
    ###
    # Update a torrent's state
    #
    def update_torrent_state()
      from = getInput("  From state:")
      to = getInput("  To state:")
      
      q = "SELECT hash, name FROM torrents WHERE tp_state = \"#{from}\";"
      q = "SELECT hash, name FROM torrents WHERE tp_state IS NULL;" if from == "NULL" || from == "null"
      
      puts "Executing query: #{q} :"
      rows = @database.execute( q )
      puts "SELECT Query returned #{rows.length} rows."
      
      return unless rows.length > 0
      
      q = "UPDATE torrents SET tp_state = \"#{to}\" WHERE tp_state = \"#{from}\";"
      q = "UPDATE torrents SET tp_state = \"#{to}\" WHERE tp_state IS NULL;" if from == "NULL" || from == "null"
      
      puts "Executing query: #{q} :"
      @database.execute( q )
      
    end
    
    
    ###
    # Display torrent job property data
    #
    def dump_jobprops( id )
      if ( id == "0" )
        q = "SELECT id, hash FROM torrents"
        rows = @database.execute( q )
        rows.each do |r|
          dump_jobprops( r[0] )
        end
        return
      end

      q = "SELECT id, hash, name FROM torrents WHERE id = \"#{id}\";"
      rows = @database.execute( q )
      puts "ID (#{id}) not found in database." if !( rows.length > 0 )
      return if ! ( rows.length > 0 )
      
      response = @utorrent.get_torrent_job_properties( rows[0][1] )
      #puts rows.inspect
      puts "Name: #{rows[0][2]}"
      
      puts "Error: No longer in uTorrent, but still in DB." if response["props"].nil?
      return if response["props"].nil?

      puts "uTorrent Build: #{response["build"]}"
      puts "Props:"
      tab = "  "
      props = response["props"][0]
      puts tab + "hash: " + props["hash"]
      puts tab + "ulrate:        " + props["ulrate"].to_s
      puts tab + "dlrate:        " + props["dlrate"].to_s
      puts tab + "superseed:     " + props["superseed"].to_s
      puts tab + "dht:           " + props["dht"].to_s
      puts tab + "pex:           " + props["pex"].to_s
      puts tab + "seed_override: " + props["seed_override"].to_s
      puts tab + "seed_ratio:    " + props["seed_ratio"].to_s
      puts tab + "seed_time:     " + props["seed_time"].to_s
      puts tab + "ulslots:       " + props["ulslots"].to_s
      puts tab + "seed_num:      " + props["seed_num"].to_s
      puts
      puts tab + "trackers: " + props["trackers"]
      puts
      puts "------------------------------------"
      puts
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
            puts @hr
            puts "Query returned #{result.length} rows."
            puts @hr
            outputQueryResults(result)
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
    # Output a pretty header
    #
    # hdr:: Header text
    #
    def putsHeader(hdr)
      puts
      puts hdr
      puts "=" * hdr.size
      puts
    
    end
    
    
    ###
    # Output a DB query
    #
    # results:: DB query results
    def outputQueryResults(results)
      $LOG.debug "Console::outputQueryResults(results)"
    
      case @omode
        when :raw
          results.each do |r|
            p r
          end
          #puts results
          
        when :pretty
          results.each do |i|
            if( i.kind_of?(Array) )
              puts i.join( " | " )
            else
              puts i
            end
          end
      end
      
    end
    
    
  end # class Console



end # module TorrentProcessor
