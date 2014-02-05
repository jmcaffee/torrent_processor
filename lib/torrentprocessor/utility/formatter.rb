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

    ###
    # Output a simple horizonal rule
    #
    def Formatter.pHr
      hr = "-"*40
      puts hr
    end

    ###
    # Output a pretty header
    #
    # hdr:: Header text
    #
    def Formatter.pHeader(hdr)
      puts
      puts hdr
      puts "=" * hdr.size
      puts
    end

    ###
    # Output a DB query
    #
    # results:: DB query results
    def Formatter.pQueryResults(results)

      case @omode
        when :raw
          results.each do |r|
            p r
          end
          #puts results

        when :pretty
          results.each do |i|
            if( i.kind_of?(Array) )
              puts i.join( " | " )
            else
              puts i
            end
          end
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
    def Formatter.pHash(hsh)
      if @omode == :raw
        puts hsh.inspect
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
          puts " #{k.ljust(maxlen)}: #{v}"
        elsif ( v.class == Hash )
          puts " #{k.ljust(maxlen)}:"
          Formatter.pHash( v )
        elsif ( v.respond_to?(:to_hsh) )
          puts " #{k.ljust(maxlen)}:"
          Formatter.pHash( v.to_hsh )
          puts " --- "
        else
          puts " #{k.ljust(maxlen)}:"
          Formatter.pArray ( v )
        end
      end # each k,v
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
    def Formatter.pArray(ary)
      if @omode == :raw
        puts ary.inspect
        return
      end # if @omode == :raw

      ary.each do |v|
        if ( v.class != Array && v.class != Hash && !v.respond_to?(:to_hsh) )
          puts "     #{v}"
        elsif ( v.class == Hash )
          Formatter.pHash( v )
        elsif ( v.respond_to?(:to_hsh) )
          Formatter.pHash( v.to_hsh )
          puts " --- "
        else
          Formatter.pArray ( v )
        end
      end # each v
    end
  end # class Formatter
end # module TorrentProcessor::Utility
