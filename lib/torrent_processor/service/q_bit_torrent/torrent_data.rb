# encoding: utf-8
##############################################################################
# File::    torrent_data.rb
# Purpose:: Torrent Data object encapsulates data for one torrent.
#
# Author::    Jeff McAffee 2015-02-19
# Copyright:: Copyright (c) 2015, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

module TorrentProcessor::Service::QBitTorrent

  class TorrentData

    attr_accessor :hash               # DB field
    attr_accessor :status             # DB field
    attr_accessor :name               # DB field
    attr_accessor :percent_progress   # DB field
    attr_accessor :ratio              # DB field
    attr_accessor :label              # DB field
    attr_accessor :msg                # DB field
    attr_accessor :folder             # DB field
    attr_accessor :uploaded
    attr_accessor :downloaded

    ###
    # TorrentData constructor
    #
    # torrent:: Hash of torrent data
    #
    def initialize(torrent)
      @hash                 = torrent['hash']
      @status               = torrent['state']
      @name                 = torrent['name']
      @percent_progress     = torrent['progress']
      @ratio                = amount_in_bytes(torrent['share_ratio'])
      @label                = '' # torrent['']  # Not supported in QBitTorrent
      @msg                  = torrent['comment']
      @folder               = torrent['save_path']
      @uploaded             = amount_in_bytes(torrent['total_uploaded'])
      @downloaded           = amount_in_bytes(torrent['total_downloaded'])

    end

    protected

    ### Normalize transfer amounts
    #

    def amount_in_bytes amount_txt
      # Handle infinity (why, oh why...)
      return amount_txt if amount_txt == '∞'

      # Ex: 646.8 KiB (657.8 KiB this session)
      # Remove (session info)
      amount = amount_txt.gsub(/\(.+\)/, '').strip

      # Convert measurements
      # B = * 1
      # KiB = * 1_024
      # MiB = * 1_048_576
      # GiB = * 1_073_741_824
      multiplier = 1.0

      if amount.include? 'GiB'
        multiplier = 1_073_741_824.0
        amount = amount.gsub('GiB','').strip

      elsif amount.include? 'MiB'
        multiplier = 1_048_576.0
        amount = amount.gsub('MiB','').strip

      elsif amount.include? 'KiB'
        multiplier = 1_024.0
        amount = amount.gsub('KiB','').strip

      elsif amount.include? 'B'
        amount = amount.gsub('B','').strip
      end

      amount = Float(amount) * multiplier
      amount.floor
    end

    public

    ###
    # Normalize percentages to integers
    # After normalization, 100% = 1000
    #
    # percent_progress and ratio are normalized
    #

    def normalize_percents
      self.percent_progress ||= 0.0
      norm_progress = (percent_progress * 1000.0).floor
      self.percent_progress = norm_progress

      self.ratio ||= 0.0
      norm_ratio = ratio
      norm_ratio = uploaded / downloaded if norm_ratio == "∞"
      norm_ratio = Float(norm_ratio)
      norm_ratio = (norm_ratio * 1000.0).floor
      self.ratio = norm_ratio
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
    # Convert the data to a hash
    #
    # *Returns*
    #
    # Hash of torrent data
    #
    def to_hsh
      hsh = {}
      hsh["hash"] = @hash
      hsh["status"] = @status
      hsh["name"] = @name
      hsh["percent_progress"] = @percent_progress
      hsh["ratio"] = @ratio
      hsh["label"] = @label
      hsh["msg"] = @msg
      hsh["folder"] = @folder

      hsh
    end
  end # class
end # module
