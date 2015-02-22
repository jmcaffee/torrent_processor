############################################################################
# File::    movie_db.rb
# Purpose:: Retrieve info from TMDB
#
# Author::    Jeff McAffee 2013-10-20
# Copyright:: Copyright (c) 2013, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

module TorrentProcessor
  module Plugin

  class MovieDB < BasePlugin
    include TorrentProcessor::Utility::Verbosable

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

    TEST_CONNECTION_CMD = '.tmdbtestcon'
    MOVIE_SEARCH_CMD    = '.tmdbmoviesearch'

    attr_reader :api_key
    attr_reader :language

    def MovieDB.register_cmds
      { TEST_CONNECTION_CMD => Command.new(MovieDB, :cmd_test_connection,    "Test the TMdb connection",
                                                {
                                                  :api_key => TorrentProcessor.configuration.tmdb.api_key,
                                                  :language => TorrentProcessor.configuration.tmdb.language
                                                }),
        MOVIE_SEARCH_CMD    => Command.new(MovieDB, :cmd_search_movie,       "Search for a movie",
                                                {
                                                  :api_key => TorrentProcessor.configuration.tmdb.api_key,
                                                  :language => TorrentProcessor.configuration.tmdb.language
                                                }),
        #"." => Command.new(IMDBPlugin, :, ""),
      }
    end

    def initialize( args = {} )
      @tag = 'MovieDB'
      parse_args args
    end

    protected

    def parse_args args
      super

      self.api_key  = args[:api_key]  if args[:api_key]
      self.language = args[:language] if args[:language]
    end

    def defaults
      {
        #:logger     => NullLogger,
      }
    end

    public

    def api_key=(key)
      Tmdb::Api.key(key)
    end

    def language=(lang)
      Tmdb::Api.language(lang)
    end

    ###
    # Test the TMDB.org connection
    #
    def cmd_test_connection(args)
      parse_args args

      log "Testing TMDB connection"
      log "..."

      result = test_connection
    end

    def cmd_search_movie(args)
      parse_args args

      # Strip off the actual command.
      movie_title  = args[:cmd].gsub(MOVIE_SEARCH_CMD, '').strip

      if movie_title.nil? || movie_title.empty?
        log 'Error: movie title argument expected'
        return
      end

      # Parse the title so we can tell user what the search text will be.
      # Not needed otherwise.
      search_text = parse_search_text(movie_title)
      log "Searching for #{search_text}"

      movies = search_movie search_text

      if movies.size <= 0
        log '...No results'
        log
      else
        log
        log "Results:"
        movies.each do |movie|
          log movie.title + " (#{movie.release_date[0..3]})"
        end
        log
      end

      return movies
    end

    ###
    # Test the TMDB.org connection
    #
    def test_connection()
      tmdb_config = Tmdb::Configuration.new
      url = tmdb_config.base_url

      # If url is not populated, it's probably because no API key has
      # been configured, or an incorrect API key has been provided.
      if url.nil?
        log "Missing TMDb url. Have you configured your TMDb API Key?"
        log "If you've configured your TMDb API Key, please confirm it is correct."
        return :abort
      end

      log "Attempting to connect to #{url}"

      movie = Tmdb::Movie.find('Fight Club')
      # Returns an array of suggested movies with the best suggestion first.
      movie = movie[0] if movie.size > 0

      if movie.title == 'Fight Club'
        log "Successful connection."
        return true
      end
    rescue
      log "Unable to connect"
      return :abort
    end

    def search_movie(text)
      if text.nil?
        log "Error: movie title argument expected"
        return []
      end

      year = get_year(text)
      search_text = parse_search_text(text)

      log "  search for #{search_text}"

      movies = Tmdb::Movie.find(search_text)

      if movies.size <= 0
        log " ...no results"

        log " trying search again with no spaces"
        search_text = search_text.gsub(' ', '')

        log "  search for #{search_text}"
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
  end # module
end # module TorrentProcessor::ProcessorPlugin
