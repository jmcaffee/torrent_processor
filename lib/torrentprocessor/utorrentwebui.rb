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
require 'torrentdata'


module TorrentProcessor
    
  ##########################################################################
  # UTorrentWebUI class
  class UTorrentWebUI

    attr_accessor :verbose
    attr_accessor :result
    attr_reader   :response
    attr_reader   :torrents
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
    def sendGetQuery(query)
      $LOG.debug "UTorrentWebUI::sendQuery( #{query} )"
    
      data = nil
      startSession()
      getToken()
      data = getQuery("#{query}&token=#{@token}")
      stopSession()
      
      return data
      
    end
    
    
    ###
    # Parse the response data (using JSON)
    #
    def parseResponse
      $LOG.debug "UTorrentWebUI::parseResponse()"
      if @response.nil? || !@response
        $LOG.debug "Response is NIL or empty."
        return
      end
      
      result = JSON.parse(@response.body)
    end
    
    
    ###
    # Get uTorrent settings
    #
    def get_utorrent_settings()
      $LOG.debug "UTorrentWebUI::get_utorrent_settings()"
    
      @url = "/gui/?action=getsettings"
      
      sendGetQuery(@url)
      result = parseResponse()
      
      @settings = result["settings"]
      
    end
    
    
    ###
    # Get a torrent's job properties
    #
    def get_torrent_job_properties(hash)
      $LOG.debug "UTorrentWebUI::get_torrent_job_properties()"

      @url = "/gui/?action=getprops&hash=#{hash}"

      sendGetQuery(@url)
      result = parseResponse()
    end


    ###
    # Send uTorrent request to remove torrent
    #
    def remove_torrent(hash)
      $LOG.debug "UTorrentWebUI::remove_torrent( hash )"
    
      @url = "/gui/?action=removedata&hash=#{hash}"
      
      sendGetQuery(@url)
      result = parseResponse()
    end
    
    
    ###
    # Get a list of Torrents
    #
    def get_torrent_list(cache_id = nil)
      $LOG.debug "UTorrentWebUI::get_torrent_list( #{cache_id} )"
      
      @url = "/gui/?list=1"
      @url = "/gui/?list=1&cache=#{cache_id}" if !cache_id.nil?
      
      sendGetQuery(@url)
      result = parseResponse()
      
      return parseListRequestResponse( result )
      
    end
      
    
    ###
    # Get a list of Torrents using a cache value
    #
    def get_torrent_list_using_cache(cache_id)
      $LOG.debug "UTorrentWebUI::get_torrent_list_using_cache( #{cache_id} )"
      # TODO: Remove this method
      @url = "/gui/?list=1&cache=#{cache_id}"
      
      sendGetQuery(@url)
      result = parseResponse()
      
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
      
      # Stash the cache
      @torrentc = response["torrentc"]
      $LOG.info "    Cache value stored: #{@torrentc}"
      
      parseTorrentListResponse( response )      if response.include?("torrents")
      parseTorrentListCacheResponse( response ) if response.include?("torrentsp")
      $LOG.error("  List Request Response does not contain either 'torrents' or 'torrentsp'") if (!response.include?("torrents") && !response.include?("torrentsp"))
      
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
    
    
  end # class UTorrentWebUI



end # module TorrentProcessor
