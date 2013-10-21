############################################################################
# File::    tmdb_plugin.rb
# Purpose:: Retrieve info from TMDB
#
# Author::    Jeff McAffee 2013-10-19
# Copyright:: Copyright (c) 2013, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

module TorrentProcessor::Plugin

  ##########################################################################
  # TMDBPlugin class
  class TMDBPlugin
    include KtCmdLine


    def TMDBPlugin.register_cmds
      { ".tmdbtestcon"      => Command.new(TMDBPlugin, :test_connection,    "Test the TMdb connection"),
        ".tmdbmoviesearch"  => Command.new(TMDBPlugin, :search_movie,       "Search for a movie"),
        #"." => Command.new(IMDBPlugin, :, ""),
      }
    end

    def initialize
      @tag = 'TMDBPlugin'
    end

    ###
    # Test the TMDB.org connection
    #
    def test_connection(args)
      $LOG.debug "#{@tag}::test_connection"
      cmdtxt  = args[0]
      kaller  = args[1]
      mdb     = kaller.moviedb

      puts "Attempting to connect to TMDB"
      puts "..."

      result = mdb.test_connection

      if result
        puts "Successful connection."
        return true
      end

      puts "Connection failed"
      return false
    end

    def search_movie(args)
      $LOG.debug "#{@tag}::search_movie"
      cmdtxt  = args[0]
      kaller  = args[1]
      mdb     = kaller.moviedb

      if cmdtxt.nil?
        puts 'Error: movie title argument expected'
        return
      end

      # Parse the title so we can tell user what the search text will be.
      # Not needed otherwise.
      search_text = mdb.parse_search_text(cmdtxt)
      puts "Searching for #{search_text}"

      movies = mdb.search_movie search_text

      if movies.size <= 0
        puts '...No results'
        puts
      else
        puts
        puts "Results:"
        movies.each do |movie|
          puts movie.title + " (#{movie.release_date[0..3]})"
        end
        puts
      end

      return movies
    end
  end # class TMDBPlugin
end # module TorrentProcessor::Plugin
