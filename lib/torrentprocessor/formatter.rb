##############################################################################
# File::    formatter.rb
# Purpose:: Console Formatter helper class.
# 
# Author::    Jeff McAffee 02/22/2012
# Copyright:: Copyright (c) 2012, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

##########################################################################
# TorrentProcessor module
module TorrentProcessor



  ##########################################################################
  # Formatter class
  class Formatter
    
    # Output mode
    @omode = :pretty
    
    
    ###
    # Set output mode
    #
    def Formatter.setOutputMode(mode)
      if [:pretty, :raw].include? mode
        @omode = mode
      end
    end


    ###
    # Return current output mode
    #
    def Formatter.outputMode
      @omode
    end


    ###
    # Toggle the output mode
    #
    def Formatter.toggleOutputMode
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
    
    

  

  end # class Formatter


end # module TorrentProcessor
