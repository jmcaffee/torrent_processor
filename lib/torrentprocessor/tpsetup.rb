##############################################################################
# File::    tpsetup.rb
# Purpose:: Torrent Processor Setup object assists with setting up TP.
#
# Author::    Jeff McAffee 08/07/2011
# Copyright:: Copyright (c) 2011, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'ktcommon/ktpath'
require 'ktcommon/ktcmdline'
require 'sqlite3'


module TorrentProcessor

  ##########################################################################
  # TPSetup class
  class TPSetup
    include KtCmdLine


    ###
    # TPSetup constructor
    #
    # controller:: controller object
    #
    def initialize(controller)
      $LOG.debug "TPSetup::initialize"

      @controller = controller
      @cfg = @controller.cfg
      @verbose = false
    end


    ###
    # Set the verbose flag
    #
    # arg:: verbose mode if true
    #
    def verbose=(arg)
      $LOG.debug "TPSetup::verbose=( #{arg} )"
      @verbose = arg
    end


    ###
    # Setup application
    #
    def setupApp()
      $LOG.debug "TPSetup::setupApp"
      setupConfig()
      setupDb()
    end


    ###
    # Check if setup has been completed.
    #
    # returns:: false if setup is not yet completed
    #
    def checkSetupCompleted()
      $LOG.debug "TPSetup::checkSetupCompleted"

      # Test for an existing config file.
      foundConfig = configExists?
      return false if !foundConfig

      # Test for an existing DB.
      foundDb = dbExists?
      return false if !foundDb

      return true
    end


    ###
    # Check if config file exists
    #
    # returns:: false if setup is not yet completed
    #
    def configExists?()
      $LOG.debug "TPSetup::configExists?()"

      # Test for an existing config file.

      foundConfig = false
      if File.exists?( File.join(@cfg[:appPath], "torrentprocessor.yml") )
        foundConfig = true
      end

      if File.exists?( File.join(@cfg[:appPath], "config.yml") )
        foundConfig = true
      end

      return false if !foundConfig

      return true
    end


    ###
    # Check if DB file exists
    #
    # returns:: false if DB doesn't exist
    #
    def dbExists?()
      $LOG.debug "TPSetup::dbExists?()"

      # Test for an existing DB.

      foundDb = false
      if File.exists?( File.join(@cfg[:appPath], "tp.db") )
        foundDb = true
      end

      return false if !foundDb

      return true
    end


    ###
    # Print a header to STDOUT. Header is surrounded with lines.
    # hdr:: header to print
    def printHeader(hdr)
      puts
      puts '-'* hdr.size
      puts hdr
      puts '-'* hdr.size
      puts
    end


    ###
    # verifyUserInputs should be called after getting user input.Asks
    # the user if they are happy with the values they supplied and gives
    # them an opportunity to change their answer or quit the program.
    def verifyUserInputs(questions, answers)
      printHeader("Verify Torrent Processor Settings:")

      questions.each_index do |i|
        puts "#{questions[i]} " + "#{answers[i]}"
      end
      puts
      choice = getInput("Is this information correct? (Y/n/q)")
      exit if choice == 'q'
      return true if choice == 'Y'
      return false
    end


    ###
    # Get data from the user.
    # questions:: array of questions.
    # returns:: array of user's answers. Index of answer matches index of question.
    def askUser(questions)
      printHeader("Torrent Processor Setup")

      answers = []
      questions.each do |tq|
        answers << getInput(tq)
      end
      answers
    end


    ###
    # Setup the config file by building a list of questions,
    # display them to the user and collecting the answers. Once the user has
    # confirmed the submitted information we can apply the answers to the
    # config file. The answers will be in the same order as the questions.
    def setupConfig()
      $LOG.debug "TPSetup::setupConfig()"
      #return getTokenValues_TEST()

      if configExists?
        choice = getInput("A configuration file already exists. Do you wish to recreate it? (Y/n)")
        return if choice != 'Y'

        puts "Deleting configuration file..."
        FileUtils.rm( File.join(@cfg[:appPath], "config.yml") ) if File.exists?( File.join(@cfg[:appPath], "config.yml") )
        FileUtils.rm( File.join(@cfg[:appPath], "torrentprocessor.yml") ) if File.exists?( File.join(@cfg[:appPath], "torrentprocessor.yml") )
      end

      questions = []
      questions << "IP of machine running uTorrent (default: 127.0.0.1) :"
      questions << "uTorrent webui port:"
      questions << "uTorrent webui user name:"
      questions << "uTorrent webui user password:"
      questions << "Folder to store logs in [full path] (default: #{@cfg[:appPath]}):"
      questions << "Max size of log file in bytes (default: 0 = no limit):"
      questions << "Processing folder for TV Shows [full path]:"
      questions << "Processing folder for Movies [full path]:"
      questions << "Processing folder for other downloads [full path] (default: TV Shows folder):"
      questions << "TMDB API Key (sign up at https://www.themoviedb.org/account/signup):"
      questions << "Final destination folder for movies (can be mapped drive):"
      questions << "No movie copying after time (24 hr format; ex: 1830):"

      answers = askUser(questions)

      # Set defaults here:
      # All questions are required (except #1, 5, and 6)

      # WebUI port
      if(answers[0].empty?)
        answers[0] = "127.0.0.1"
      end

      # Log dir
      if(answers[4].empty?)
        answers[4] = @cfg[:appPath]
      end

      # Max size of log file
      if(answers[5].empty?)
        answers[5] = 0
      else
        answers[5] = Integer(answers[5])
      end

      # Processing folder (other)
      if(answers[8].empty?)
        answers[8] = answers[6]
      end

      # TMDB API Key
      if(answers[9].empty?)
        answers[9] = ''
      end

      # Target movies folder
      if(answers[10].empty?)
        answers[10] = ''
      end

      # Don't copy movies after a certain time
      if(answers[11].empty?)
        answers[11] = -1
      end

      while(!verifyUserInputs(questions, answers))
        answers = askUser(questions)
      end

      @cfg[:ip]                   = answers[0]
      @cfg[:port]                 = answers[1]
      @cfg[:user]                 = answers[2]
      @cfg[:pass]                 = answers[3]
      @cfg[:logdir]               = answers[4]
      @cfg[:maxlogsize]           = answers[5]
      @cfg[:tvprocessing]         = answers[6]
      @cfg[:movieprocessing]      = answers[7]
      @cfg[:otherprocessing]      = answers[8]
      @cfg[:tmdb_api_key]         = answers[9]
      @cfg[:target_movies_path]   = answers[10]
      @cfg[:no_copy_movie_time]   = answers[11]

      FileUtils.mkdir_p( @cfg[:appPath] )
      c = Config.new
      c.cfg = @cfg
      c.save
    end


    ###
    # Setup the DB file by creating the DB and tables.
    #
    def setupDb()
      $LOG.debug "TPSetup::setupDb()"

      if dbExists?
        choice = getInput("A database already exists. Do you wish to recreate it? (Y/n)")
        return if choice != 'Y'

        puts "Deleting database..."
        FileUtils.rm( File.join(@cfg[:appPath], "tp.db") )
      end

      puts "Creating database..."
      database = SQLite3::Database.new( File.join(@cfg[:appPath], "tp.db") )

      schema = <<EOQ
-- Create the torrents table
CREATE TABLE torrents (
  id INTEGER PRIMARY KEY,
  hash TEXT UNIQUE,
  created DATE,
  modified DATE,
  status NUMERIC,
  name TEXT,
  percent_progress NUMERIC,
  ratio NUMERIC,
  label TEXT,
  msg TEXT,
  folder TEXT,
  tp_state TEXT DEFAULT NULL
);
--  Create an update trigger
CREATE TRIGGER update_torrents AFTER UPDATE  ON torrents
BEGIN

UPDATE torrents SET modified = DATETIME('NOW')
         WHERE rowid = NEW.rowid;

END;
--
--  Also create an insert trigger
--    NOTE  AFTER keyword ------v
CREATE TRIGGER insert_torrents AFTER INSERT ON torrents
BEGIN

UPDATE torrents SET created = DATETIME('NOW')
         WHERE rowid = NEW.rowid;

UPDATE torrents SET modified = DATETIME('NOW')
         WHERE rowid = NEW.rowid;

END;
--
--
--
-- Create the torrents_info table
CREATE TABLE torrents_info (
  id INTEGER PRIMARY KEY,
  cache_id TEXT,
  created DATE,
  modified DATE
);
--  Create an update trigger
CREATE TRIGGER update_torrents_info AFTER UPDATE  ON torrents_info
BEGIN

UPDATE torrents_info SET modified = DATETIME('NOW')
         WHERE rowid = NEW.rowid;

END;
--
--  Also create an insert trigger
--    NOTE  AFTER keyword ------------v
CREATE TRIGGER insert_torrents_info AFTER INSERT ON torrents_info
BEGIN

UPDATE torrents_info SET created = DATETIME('NOW')
         WHERE rowid = NEW.rowid;

UPDATE torrents_info SET modified = DATETIME('NOW')
         WHERE rowid = NEW.rowid;

END;
--
-- Insert a cache record as part of initialization
INSERT INTO torrents_info (cache_id) values (NULL);
--
--
--
-- Create the app_lock table
CREATE TABLE app_lock (
  id INTEGER PRIMARY KEY,
  locked TEXT
);
--
-- Insert a lock record as part of initialization
INSERT INTO app_lock (locked) values ("N");
EOQ
      database.execute_batch( schema )
    end


  end # class TPSetup



end # module TorrentProcessor
