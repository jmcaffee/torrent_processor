##############################################################################
# File::    rssplugin.rb
# Purpose:: RSS uTorrent Plugin class
#
# Author::    Jeff McAffee 02/25/2012
# Copyright:: Copyright (c) 2012, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require_relative '../utility/formatter'

module TorrentProcessor::Plugin

  class RSSPlugin
    include KtCmdLine
    include TorrentProcessor::Utility

    attr_reader :database, :utorrent


    def RSSPlugin.register_cmds
      { ".rssfeeds" =>      Command.new(RSSPlugin, :rss_feeds,          "Display current RSS feeds"),
        ".rssfilters" =>    Command.new(RSSPlugin, :rss_filters,        "Display current RSS filters"),
        ".feeddetails" =>   Command.new(RSSPlugin, :rss_feed_details,   "Display details of an RSS feed"),
        ".filterdetails" => Command.new(RSSPlugin, :rss_filter_details, "Display details of an RSS filter"),
        #"." => Command.new(RSSPlugin, :, ""),
      }
    end

    def defaults
      {
        :logger => NullLogger
      }
    end

    def parse_args args
      args = defaults.merge args
      @logger   = args.fetch(:logger)
      Formatter.logger = @logger
      @database = args.fetch(:database)
      @utorrent = args.fetch(:utorrent)
    end

    def log msg = ''
      @logger.log msg
    end

    def rss_feeds(args)
      cmd = args.fetch(:cmd)
      parse_args args

      data = utorrent.get_torrent_list()
      display_current_feed_list( utorrent.rssfeeds )
      #puts data
      log " #{utorrent.rssfeeds.length} Feed(s) found."
      log

      return true
    end


    def rss_filters(args)
      cmd = args.fetch(:cmd)
      parse_args args

      data = utorrent.get_torrent_list()
      display_current_feed_list( utorrent.rssfilters )
      #puts data
      log " #{utorrent.rssfilters.length} Filter(s) found."
      log

      return true
    end


    ###
    # Display RSS feed details
    #
    def rss_feed_details(args)
      cmd = args.fetch(:cmd)
      parse_args args

      utorrent.get_torrent_list()
      hashes = select_rss_hashes( utorrent.rssfeeds )
      return true if hashes.nil?

      hashes.each do |feed|
        Formatter.print_rule
        hsh = feed[0]
        Formatter.print(utorrent.rssfeeds[hsh].to_hsh)
      end # each torr

      Formatter.print_rule

      return true
    end


    ###
    # Display RSS filter details
    #
    def rss_filter_details(args)
      cmd = args.fetch(:cmd)
      parse_args args

      cmd_parts = cmd.split
      hashes = []
      utorrent.get_torrent_list()
      if (cmd_parts.length > 1)
        fid = Integer(cmd_parts[1])
        hashes = display_current_feed_list( utorrent.rssfilters )
        newhashes = []
        newhashes << hashes[fid].clone
        hashes = newhashes.clone
      else
        hashes = select_rss_hashes( utorrent.rssfilters )
      end
      return true if hashes.nil?

      hashes.each do |filter|
        Formatter.print_rule
        hsh = filter[0]
        Formatter.print(utorrent.rssfilters[hsh].to_hsh)
      end # each torr

      Formatter.print_rule

      return true
    end


    ###
    # Display and return an indexed hash of the current feeds/filters
    #
    # @returns hash of arrays containing torrent feeds (or filters) hash and name. The hash is keyed by 1-based index.
    #
    def display_current_feed_list( fdata )
      len = fdata.length
      if len == 0
        log "No feeds to display"
        return nil
      end

      Formatter.print_rule
      log " #  | Name"
      Formatter.print_rule
      log

      # Have to build an accompanying hash because we can't fetch a value
      # from a hash using an index.
      indexed_hsh = {}
      #puts "-*"*30
      #puts fdata.inspect
      #puts "-*"*30
      fdata.each_with_index do |(k,v),i|
        i += 1
        log "#{i}\t#{v.feed_name}"
        # FIXME: don't need to send a tuple here.
        indexed_hsh[i] = [v.feed_name, v.feed_name]
      end

      log
      Formatter.print_rule
      log

      return indexed_hsh
    end


    ###
    # Return an array containing torrent hashes and names. The data is selected by the user via index
    #
    def select_rss_hashes( fdata )
      indexed_hsh = display_current_feed_list( fdata )
      index = getInput(" Select one (0 for all, <blank> for none): ")

      # Return all feed/filter hashes in an array of arrays containing the hash and the name
      hashes = []
      if index == "0"
        fdata.each do |k,v|
          hashes << [v.feed_name, v.feed_name]
        end
        return hashes
      end

      return nil if index.empty?

      begin
        index = Integer(index)
      rescue Exception => e
        # Handle the case where user enters text instead of a valid number.
        # We can just fall through because the Invalid Entry check below
        # will react appropriately.
      end

      if !indexed_hsh.has_key?(index)
        log " Invalid entry!"
        log
        # Re-display the list
        return select_rss_hashes(fdata)
      end

      # Return the selected hash in an array
      return ([] << indexed_hsh[index])
    end
  end # class RSSPlugin
end # module TorrentProcessor::Plugin
