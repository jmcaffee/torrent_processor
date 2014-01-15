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
    def initialize(args)
      @verbose = false
      parse_args args
    end

    def parse_args args
      args = defaults.merge args
      @db = args[:database] if args[:database]
    end

    def defaults
      {}
    end

    ###
    # Set the verbose flag
    #
    # arg:: verbose mode if true
    #
    def verbose=(arg)
      @verbose = arg
    end

    ###
    # Setup application
    #
    def setup_app()
      setup_config()
      setup_db()
    end

    def config_needs_upgrade?
      needs_upgrade = false
      File.read(cfg_path).each_line do |line|
        if line.include?('appPath')
          return true
        end
      end

      false
    end

    def backup_config
      timestamp = DateTime.now.strftime.gsub(':','_')
      dest = File.join(app_data_path, "config-#{timestamp}_bak.yml")

      FileUtils.cp cfg_path, dest
    end

    def upgrade_config path
      old_config = Config.new(path).load
      TorrentProcessor.configure do |config|
        config.app_path         = old_config[:appPath]
        config.logging          = old_config[:logging]
        config.log_dir          = old_config[:logdir]
        config.max_log_size     = old_config[:maxlogsize]
        config.tv_processing    = old_config[:tvprocessing]
        config.movie_processing = old_config[:movieprocessing]
        config.other_processing = old_config[:otherprocessing]
        config.other_processing = old_config[:otherprocessing]

        # Create an empty hash if needed.
        config.filters = {} if config.filters.nil?

        # Copy filters hash.
        old_config[:filters].each do |k,v|
          config.filters[k] = v
        end

        config.utorrent.ip    = old_config[:ip]
        config.utorrent.port  = old_config[:port]
        config.utorrent.user  = old_config[:user]
        config.utorrent.pass  = old_config[:pass]
        config.utorrent.pass  = old_config[:pass]

        config.tmdb.api_key             = old_config[:tmdb_api_key]
        config.tmdb.target_movies_path  = old_config[:target_movies_path]
        config.tmdb.can_copy_start_time = old_config[:can_copy_start_time]
        config.tmdb.can_copy_stop_time  = old_config[:can_copy_stop_time]
      end

      TorrentProcessor.save_configuration(File.join(path, 'config.yml'))
    end

    ###
    # Check if setup has been completed.
    #
    # returns:: false if setup is not yet completed
    #
    def check_setup_completed()
      return true if(config_exists? && db_exists?)
      false
    end

  private

    def cfg
      TorrentProcessor.configuration
    end

    def cfg_path
      File.join(app_data_path, 'config.yml')
    end

    def app_data_path
      appdata = ENV['APPDATA'].gsub('\\','/')
      File.join(appdata, 'torrentprocessor')
    end

    def database
      @db
    end
    ###
    # Check if config file exists
    #
    # returns:: false if setup is not yet completed
    #
    def config_exists?()
      File.exists? cfg_path
    end

    ###
    # Check if DB file exists
    #
    # returns:: false if DB doesn't exist
    #
    def db_exists?()
      return File.exists?(database.filepath)
    end

    ###
    # Print a header to STDOUT. Header is surrounded with lines.
    # hdr:: header to print
    def print_header(hdr)
      puts
      puts '-'* hdr.size
      puts hdr
      puts '-'* hdr.size
      puts
    end

    ###
    # Setup the config file by building a list of questions,
    # display them to the user and collecting the answers. Once the user has
    # confirmed the submitted information we can apply the answers to the
    # config file. The answers will be in the same order as the questions.
    def setup_config()
      if config_exists?
        choice = getInput("A configuration file already exists. Do you wish to recreate it? (Y/n)")
        return if choice != 'Y'

        puts "Deleting configuration file..."
        FileUtils.rm( cfg_path ) if File.exists?(cfg_path)
      end

      questions = []
      questions << ["IP of machine running uTorrent",                     cfg.utorrent.ip]
      questions << ["uTorrent webui port",                                cfg.utorrent.port]
      questions << ["uTorrent webui user name",                           cfg.utorrent.user]
      questions << ["uTorrent webui user password",                       cfg.utorrent.pass]
      questions << ["Folder to store logs in (full path)",                cfg.appPath]
      questions << ["Max size of log file in bytes (0 = no limit)",       cfg.maxlogsize]
      questions << ["Processing folder for TV Shows (full path)",         cfg.tvprocessing]
      questions << ["Processing folder for Movies (full path)",           cfg.movieprocessing]
      questions << ["Processing folder for other downloads (full path)",  cfg.otherprocessing]
      questions << ["TMDB API Key (sign up at https://www.themoviedb.org/account/signup)", cfg.tmdb.api_key]
      questions << ["Final destination folder for movies (can be mapped drive)",  cfg.tmdb.target_movies_path]
      questions << ["Allow movie copying after time (24 hr format; ex: 00:00)",   cfg.tmdb.can_copy_start_time]
      questions << ["Allow movie copying until time (24 hr format; ex: 18:30)",   cfg.tmdb.can_copy_stop_time]

      answers = ask_user(questions)

      # Set defaults here:
      # All questions are required (except #1, 5, and 6)

      # WebUI port
      if is_empty?(answers[0])
        answers[0] = "127.0.0.1"
      end

      # Log dir
      if is_empty?(answers[4])
        answers[4] = cfg.app_path
      end

      # Max size of log file
      if is_empty?(answers[5])
        answers[5] = 0
      else
        answers[5] = Integer(answers[5])
      end

      # Processing folder (other)
      if is_empty?(answers[8])
        answers[8] = answers[6]
      end

      # TMDB API Key
      if is_empty?(answers[9])
        answers[9] = ''
      end

      # Target movies folder
      if is_empty?(answers[10])
        answers[10] = ''
      end

      # Don't copy movies after a certain time
      if is_empty?(answers[11])
        answers[11] = "00:00"
      end

      # Don't copy movies after a certain time
      if is_empty?(answers[12])
        answers[12] = "23:59"
      end

      while(!verify_user_inputs(questions, answers))
        answers = ask_user(questions)
      end

      cfg.utorrent.ip               = answers[0]
      cfg.utorrent.port             = answers[1]
      cfg.utorrent.user             = answers[2]
      cfg.utorrent.pass             = answers[3]
      cfg.logdir                    = answers[4]
      cfg.maxlogsize                = answers[5]
      cfg.tvprocessing              = answers[6]
      cfg.movieprocessing           = answers[7]
      cfg.otherprocessing           = answers[8]
      cfg.tmdb.tmdb_api_key         = answers[9]
      cfg.tmdb.target_movies_path   = answers[10]
      cfg.tmdb.can_copy_start_time  = answers[11]
      cfg.tmdb.can_copy_stop_time   = answers[12]

      FileUtils.mkdir_p( cfg.app_path )
      # By default, saves to the app_path location.
      TorrentProcessor.save_configuration
    end

    ###
    # verify_user_inputs should be called after getting user input.Asks
    # the user if they are happy with the values they supplied and gives
    # them an opportunity to change their answer or quit the program.
    def verify_user_inputs(questions, answers)
      print_header("Verify Torrent Processor Settings:")

      questions.each_index do |i|
        if questions[i].is_a? Array
          puts "#{questions[i][0]}: " + "#{answers[i]}"
        else
          puts "#{questions[i]}: " + "#{answers[i]}"
        end
      end
      puts
      choice = getInput("Is this information correct? (Y/n/q)")
      exit if choice == 'q'
      return true if choice == 'Y'
      false
    end

    ###
    # Get data from the user.
    # questions:: array of questions.
    # returns:: array of user's answers. Index of answer matches index of question.
    def ask_user(questions)
      print_header("Torrent Processor Setup")

      answers = []
      questions.each do |tq|
        if tq.is_a?(Array)
          answers << get_input_with_default(tq[0], tq[1])
          if answers.last.nil? || answers.last.empty?
            answers.pop
            answers << tq[1]
          end
        else
          answers << getInput(tq)
        end
      end
      answers
    end

    def get_input_with_default question, default
      custom_question = question + " [#{default}]: "
      getInput custom_question
    end

    def is_empty? var
      return true if var.nil?

      return true if var.is_a?(String) && var.empty?

      false
    end

    ###
    # Setup the DB file by creating the DB and tables.
    #
    def setup_db()
      if db_exists?
        choice = getInput("A database already exists. Do you wish to recreate it? (Y/n)")
        return if choice != 'Y'

        puts "Deleting database..."
        FileUtils.rm(database.filepath)
      end

      puts "Creating database..."
      database.create_database
    end
  end # class TPSetup
end # module TorrentProcessor
