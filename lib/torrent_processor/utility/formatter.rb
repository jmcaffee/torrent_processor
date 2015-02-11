##############################################################################
# File::    formatter.rb
# Purpose:: Console Formatter helper class.
#
# Author::    Jeff McAffee 02/22/2012
# Copyright:: Copyright (c) 2012, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

module TorrentProcessor::Utility

  class Formatter

    # Output mode
    @omode = :pretty

    ###
    # Set output mode
    #
    def Formatter.set_output_mode(mode)
      if [:pretty, :raw].include? mode
        @omode = mode
      end
    end

    ###
    # Return current output mode
    #
    def Formatter.output_mode
      @omode
    end

    ###
    # Toggle the output mode
    #
    def Formatter.toggle_output_mode
      @omode = (@omode == :raw ? :pretty : :raw )
    end

    def Formatter.logger=(logger_class)
      @logger = logger_class
    end

    def Formatter.logger
      @logger ||= NullLogger
    end

    def Formatter.log msg = ''
      return if msg.nil?
      self.logger.log msg
    end

    ###
    # Output a simple horizonal rule
    #
    def Formatter.print_rule
      hr = "-"*40
      log hr
    end

    ###
    # Output a pretty header
    #
    # hdr:: Header text
    #
    def Formatter.print_header(hdr)
      log
      log hdr
      log "=" * hdr.size
      log
    end

    ###
    # Output a DB query
    #
    # results:: DB query results
    def Formatter.print_query_results(results)

      case output_mode
        when :raw
          results.each do |r|
            log r
          end
          #puts results

        when :pretty
          results.each do |i|
            if( i.kind_of?(Array) )
              log i.join( " | " )
            else
              log i
            end
          end
      end
    end

    def Formatter.print obj
      type = obj.class.to_s
      case type
      when 'Hash'
        print_hash(obj)
      when 'Array'
        print_array(obj)
      else
        log obj
        raise 'ERROR'
        #puts 'ERROR'
      end
    end

    ###
    # Print a hash in :pretty or :raw mode
    #
    # *Args*
    #
    # +hsh+ -- Hash to print
    #
    # *Returns*
    #
    # nothing
    #
    def Formatter.print_hash(hsh)
      if @omode == :raw
        log hsh.inspect
        return
      end # if @omode == :raw

      # Find the max lenght of the keys.
      maxlen = 0
      hsh.each do |k,v|
        maxlen = (k.length > maxlen ? k.length : maxlen)
      end # each k,v

      # Cap the max length at 40 chars.
      maxlen = 40 if maxlen > 40

      hsh.each do |k,v|
        if ( v.class != Array && v.class != Hash && !v.respond_to?(:to_hsh))
          log " #{key_to_string(k).ljust(maxlen)}: #{v}"
        elsif ( v.class == Hash )
          log " #{key_to_string(k).ljust(maxlen)}:"
          Formatter.print_hash( v )
        elsif ( v.respond_to?(:to_hsh) )
          log " #{key_to_string(k).ljust(maxlen)}:"
          Formatter.print_hash( v.to_hsh )
          log " --- "
        else
          log " #{key_to_string(k).ljust(maxlen)}:"
          Formatter.print_array ( v )
        end
      end # each k,v
    end

    def Formatter.key_to_string key
      if Symbol.all_symbols.include? key
        ":#{key}"
      else
        key
      end
    end

    ###
    # Print an array in :pretty or :raw mode
    #
    # *Args*
    #
    # +ary+ -- Array to print
    #
    # *Returns*
    #
    # nothing
    #
    def Formatter.print_array(ary)
      if @omode == :raw
        log ary.inspect
        return
      end # if @omode == :raw

      ary.each do |v|
        if ( v.class != Array && v.class != Hash && !v.respond_to?(:to_hsh) )
          log "     #{v}"
        elsif ( v.class == Hash )
          Formatter.print_hash( v )
        elsif ( v.respond_to?(:to_hsh) )
          Formatter.print_hash( v.to_hsh )
          log " --- "
        else
          Formatter.print_array ( v )
        end
      end # each v
    end
  end # class Formatter
end # module TorrentProcessor::Utility
