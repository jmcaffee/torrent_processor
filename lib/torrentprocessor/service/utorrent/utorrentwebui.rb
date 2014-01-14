##############################################################################
# File::    utorrentwebui.rb
# Purpose:: Web UI object for uTorrent.
#
# Author::    Jeff McAffee 07/31/2011
# Copyright:: Copyright (c) 2011, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'ktcommon/ktpath'
require 'ktcommon/ktcmdline'
require 'json/pure'
require 'net/http'
require 'hpricot'

require_relative 'torrent_data'
require_relative 'rss_torrent_data'


module TorrentProcessor::Service::UTorrent

  class UTorrentWebUI

    attr_accessor :verbose
    attr_accessor :result
    attr_reader   :response
    attr_reader   :torrents
    attr_reader   :rssfeeds
    attr_reader   :rssfilters
    attr_reader   :settings

    ###
    # Processor constructor
    #
    def initialize(ip, port, user, pass)
      $LOG.debug "UTorrentWebUI::initialize( ip:#{ip}, port:#{port} user:#{user} pass:#{pass}"

      @ip         = ip
      @port       = port
      @user       = user
      @pass       = pass
      @base_url   = "/gui/?"
      @url        = ""
      @result     = nil
      @http       = nil
      @token      = nil
      @verbose    = false
      @settings   = Array.new
      @torrentc   = nil

      @torrents         = Hash.new
      @torrents_removed = Hash.new
      @rssfeeds         = Hash.new
      @rssfilters       = Hash.new

    end


    ###
    # Start a HTTP session
    #
    # returns:: HTTP object
    #
    def startSession()
      $LOG.debug "UTorrentWebUI::startSession()"
      @http = Net::HTTP.start(@ip, @port)
    end


    ###
    # Stop a HTTP session
    #
    def stopSession()
      $LOG.debug "UTorrentWebUI::stopSession()"
      @http.finish
    end


    ###
    # Send a GET query
    #
    # returns:: response body
    #
    def getQuery(query)
      $LOG.debug "UTorrentWebUI::getQuery( #{query} )"
      req = Net::HTTP::Get.new(query)
      req.basic_auth @user, @pass
      req["cookie"] = @cookie if @cookie

      if @verbose
        puts "  REQUEST HEADERS:"
        req.each_header do |k,v|
          puts "    #{k}  =>  #{v}"
        end
        puts
      end # if @verbose

      @response = @http.request(req)

      if @verbose
        puts "  RESPONSE HEADERS:"
        @response.each_header do |k,v|
          puts "    #{k}  =>  #{v}"
        end
        puts
      end # if @verbose

      data = @response.body
      raise "Invalid response. Check the address, login and password of the server." if data.nil? || data.empty?

      $LOG.debug "  Response Body: #{data}"
      data
    end


    ###
    # Get the uTorrent token for queries
    #
    # returns:: token
    def getToken()
      $LOG.debug "UTorrentWebUI::getToken()"
      getQuery("/gui/token.html")
      data = Hpricot(@response.body)
      @token = data.at("div[#token]").inner_html
      $LOG.debug "  Token: #{@token}"

      storeCookie()
      @token
    end


    ###
    # Store the cookie if sent
    #
    def storeCookie()
      tmpcookie = @response["set-cookie"]
      @cookie = tmpcookie.split(";")[0] if !tmpcookie.nil?
      $LOG.debug "  Cookie set: #{@cookie}" if !tmpcookie.nil?

    end


    ###
    # Send a GET query
    #
    # query:: Query to send
    #
    def send_get_query(query)
      $LOG.debug "UTorrentWebUI::send_get_query( #{query} )"

      data = nil
      startSession()
      getToken()
      data = getQuery("#{query}&token=#{@token}")
      stopSession()

      return data

    end



    ###
    # Get uTorrent settings
    #
    def get_utorrent_settings()
      $LOG.debug "UTorrentWebUI::get_utorrent_settings()"

      @url = "/gui/?action=getsettings"

      send_get_query(@url)
      result = parse_response()

      @settings = result["settings"]

    end


    ###
    # Get a torrent's job properties
    #
    def get_torrent_job_properties(hash)
      $LOG.debug "UTorrentWebUI::get_torrent_job_properties()"

      @url = "/gui/?action=getprops&hash=#{hash}"

      send_get_query(@url)
      result = parse_response()
    end


    ###
    # Set torrent job properties
    #
    # props: hash of hashes
    #   Expected format:
    #     {hash1 => {'prop1' => 'value1', 'prop2' => 'value2'},
    #      hash2 => {'prp1' => 'val1', 'prp2' => 'val2'}}
    def set_job_properties(props)
      $LOG.debug "UTorrentWebUI::set_job_properties( props )"

      urlRoot = "/gui/?action=setprops"
      jobprops = ""

      props.each do |hash, propset|
        jobprops = "&hash=#{hash}"
        propset.each do |property, value|
          jobprops += "&s=#{property}&v=#{value}"
        end
      end

      raise "Invalid job properties provided to UTorrentWebUI:set_job_properties: #{props.inspect}" if jobprops.empty?
      @url = urlRoot + jobprops
      send_get_query(@url)
      result = parse_response()
    end


    ###
    # Send uTorrent request to remove torrent
    #
    def remove_torrent(hash)
      $LOG.debug "UTorrentWebUI::remove_torrent( hash )"

      @url = "/gui/?action=removedata&hash=#{hash}"

      send_get_query(@url)
      result = parse_response()
    end


    ###
    # Get a list of Torrents
    #
    def get_torrent_list(cache_id = nil)
      $LOG.debug "UTorrentWebUI::get_torrent_list( #{cache_id} )"

      @url = "/gui/?list=1"
      @url = "/gui/?list=1&cache=#{cache_id}" if !cache_id.nil?

      send_get_query(@url)
      result = parse_response()

      return parseListRequestResponse( result )

    end


    ###
    # Get a list of Torrents using a cache value
    #
    def get_torrent_list_using_cache(cache_id)
      $LOG.debug "UTorrentWebUI::get_torrent_list_using_cache( #{cache_id} )"
      # TODO: Remove this method
      @url = "/gui/?list=1&cache=#{cache_id}"

      send_get_query(@url)
      result = parse_response()

      return parseListRequestResponse( result )

    end


    ###
    # Parse a response result from a torrent list request
    #
    # response:: the JSON parsed reponse
    #
    def parseListRequestResponse(response)
      $LOG.debug "UTorrentWebUI::parseListRequestResponse(response)"

      # Clear out the torrents hash
      @torrents.clear unless @torrents.nil?

      # Clear out the removed torrents hash
      @torrents_removed.clear unless @torrents_removed.nil?

      # Clear out the RSS Feeds hash
      @rssfeeds.clear unless @rssfeeds.nil?

      # Clear out the RSS Filters hash
      @rssfilters.clear unless @rssfilters.nil?

      # Stash the cache
      @torrentc = response["torrentc"]
      $LOG.info "    Cache value stored: #{@torrentc}"

      parseTorrentListResponse( response )      if response.include?("torrents")
      parseTorrentListCacheResponse( response ) if response.include?("torrentsp")
      $LOG.error("  List Request Response does not contain either 'torrents' or 'torrentsp'") if (!response.include?("torrents") && !response.include?("torrentsp"))

      parseRssFeedsListResponse( response )     if response.include?("rssfeeds")
      $LOG.info("  List Request Response does not contain RSS Feed data") if (!response.include?("rssfeeds"))

      parseRssFiltersListResponse( response )   if response.include?("rssfilters")
      $LOG.info("  List Request Response does not contain RSS Filter data") if (!response.include?("rssfilters"))

      return response
    end


    ###
    # Parse a response result from a torrent list request
    #
    # response:: the JSON parsed reponse
    #
    def parseTorrentListResponse(response)
      $LOG.debug "UTorrentWebUI::parseTorrentListResponse(response)"
      torrents = response["torrents"]

      # torrents is an array of arrays
      torrents.each do |t|
        td = TorrentData.new(t)
        @torrents[td.hash] = td
      end

    end


    ###
    # Parse a response result from a torrent list cache request
    #
    # response:: the JSON parsed reponse
    #
    def parseTorrentListCacheResponse(response)
      $LOG.debug "UTorrentWebUI::parseTorrentListCacheResponse(response)"
      torrents = response["torrentsp"]

      # torrents is an array of arrays
      torrents.each do |t|
        td = TorrentData.new(t)
        @torrents[td.hash] = td
      end

      # Store the 'removed' torrents
      removed = response["torrentsm"]
      removed.each do |t|
        td = TorrentData.new(t)
        @torrents_removed[td.hash] = td
      end

    end


    ###
    # Parse a rssfeed response result from a torrent list request
    #
    # response:: the JSON parsed reponse
    #
    def parseRssFeedsListResponse(response)
      $LOG.debug "UTorrentWebUI::parseRssFeedsListResponse(response)"
      feeds = response["rssfeeds"]

      # feeds is an array of arrays
      feeds.each do |f|
        feed = RSSFeed.new(f)
        @rssfeeds[feed.feed_name] = feed
      end

    end


    ###
    # Parse a rssfilter response result from a torrent list request
    #
    # response:: the JSON parsed reponse
    #
    def parseRssFiltersListResponse(response)
      $LOG.debug "UTorrentWebUI::parseRssFiltersListResponse(response)"
      filters = response["rssfilters"]

      # filters is an array of arrays
      filters.each do |f|
        filter = RSSFilter.new(f)
        @rssfilters[filter.feed_name] = filter
      end

    end


    ###
    # Set the verbose flag
    #
    # arg:: verbose mode if true
    #
    def verbose=(arg)
      $LOG.debug "UTorrentWebUI::verbose=( #{arg} )"
      @verbose = arg
    end


    ###
    # Indicates if there are torrents that have been removed.
    #
    # returns:: none
    #
    def torrents_removed?()
      $LOG.debug "UTorrentWebUI::torrents_removed?()"
      return false if (@removed_torrents.nil? || @removed_torrents.length == 0)
      return true
    end


    ###
    # Return the cache token
    #
    def cache()
      $LOG.debug "UTorrentWebUI::cache()"

      return @torrentc
    end

  private

    ###
    # Parse the response data (using JSON)
    #
    def parse_response
      $LOG.debug "UTorrentWebUI::parse_response()"
      if @response.nil? || !@response
        $LOG.debug "Response is NIL or empty."
        return
      end

      result = JSON.parse(@response.body)
    end
  end # class UTorrentWebUI
end # module TorrentProcessor::Service

