############################################################################
# File::    movie_db.rb
# Purpose:: Retrieve info from TMDB
#
# Author::    Jeff McAffee 2013-10-20
# Copyright:: Copyright (c) 2013, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

module TorrentProcessor::Plugin

  class MovieDB
    require 'themoviedb'

    # Source types to strip from filenames before searching DB.
    SOURCE_TYPES = [
        'dsrip',
        'dvbrip',
        'dvdr',
        'dvdrip',
        'dvdscr',
        'hdtv',
        'hr.hdtv',
        'hr.pdtv',
        'satrip',
        'svcd',
        'tvrip',
        'webrip',
        '720p',
        '1080i',
        '1080p',
        'xvid',
        'ac3',
        'bluray',
        'x264',
      ]

    # Extensions to strip from filenames before searching DB.
    EXT_TYPES = [
        '.mkv',
        '.avi',
        '.mp4',
        '.m4v',
      ]


    def MovieDB.register_cmds
      { ".tmdbtestcon"      => Command.new(MovieDB, :cmd_test_connection,    "Test the TMdb connection"),
        ".tmdbmoviesearch"  => Command.new(MovieDB, :cmd_search_movie,       "Search for a movie"),
        #"." => Command.new(IMDBPlugin, :, ""),
      }
    end

    def initialize(api_key)
      @tag = 'MovieDB'
      Tmdb::Api.key(api_key)
      Tmdb::Api.language("en")
    end


    ###
    # Test the TMDB.org connection
    #
    def cmd_test_connection(args)
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

    def cmd_search_movie(args)
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

    ###
    # Test the TMDB.org connection
    #
    def test_connection()
      $LOG.debug "#{@tag}::test_connection"

      tmdb_config = Tmdb::Configuration.new
      $LOG.info "#{@tag} Attempting to connect to #{tmdb_config.base_url}"

      movie = Tmdb::Movie.find('Fight Club')
      # Returns an array of suggested movies with the best suggestion first.
      movie = movie[0] if movie.size > 0

      if movie.title == 'Fight Club'
        $LOG.info "#{@tag} Successful connection."
        return true
      end

      $LOG.error "#{@tag} Unable to connect"
      return false
    end

    def search_movie(text)
      $LOG.debug "#{@tag}::search_movie[ #{text} ]"

      if text.nil?
        $LOG.error "#{@tag} Error: movie title argument expected"
        return []
      end

      year = get_year(text)
      search_text = parse_search_text(text)

      $LOG.info "#{@tag}   search for #{search_text}"

      movies = Tmdb::Movie.find(search_text)

      if movies.size <= 0
        $LOG.info "#{@tag}  ...no results"

        $LOG.info "#{@tag}  trying search again with no spaces"
        search_text = search_text.gsub(' ', '')

        $LOG.info "#{@tag}   search for #{search_text}"
        movies = Tmdb::Movie.find(search_text)
      end

      return movies
    end

    def parse_search_text(text)
      test_text = text
      test_text = strip_source_type(test_text)
      test_text = strip_year(test_text)
      test_text = strip_extension(test_text)
      test_text = test_text.gsub('.', ' ')
      test_text = test_text.gsub('-', ' ')
      test_text.strip
    end

    def strip_source_type(text)
      # Remove trailing part of string from point source type is found, on.
      SOURCE_TYPES.each do |typ|
        if text.downcase.include? typ
          text = text[0...text.downcase.index(typ)]
        end
      end

      text
    end

    def strip_year(text)
      i = text =~/(\d{4})/
      unless i.nil?
        if text.length > i + 4
          text = text[0...i] + text[(i+4)..-1]
        else
          text = text[0...i]
        end # if
      end
      text
    end

    def strip_extension(text)
      # Remove trailing part of string from point extension type is found, on.
      EXT_TYPES.each do |typ|
        if text.downcase.include? typ
          text = text[0...text.downcase.index(typ)]
        end
      end

      text
    end

    def get_year(text)
      /(?<year>\d{4})/ =~ text
      year
    end

    def best_pics(movies, title, year)
      # Movie.find returns an array of suggested movies with the best suggestion first.
      best_picks = []
      movies.each do |movie|
        unless year.nil?
          if movie.release_date[0..3] == year
            best_picks << movie
            next
          end
        end

        if movie.title.downcase == title.downcase
          best_picks << movie
        end
      end

      best_picks
    end
  end # class MovieDB
end # module TorrentProcessor::ProcessorPlugin
