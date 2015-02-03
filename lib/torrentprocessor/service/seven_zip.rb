############################################################################
# File::    seven_zip.rb
# Purpose:: Interface to windows 7Zip utility
#
# Author::    Jeff McAffee 2014-01-05
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

# 7-Zip Help
#
#
# 7-Zip 9.20  Copyright (c) 1999-2010 Igor Pavlov  2010-11-18
#
# Usage: 7z <command> [<switches>...] <archive_name> [<file_names>...]
#        [<@listfiles...>]
#
# <Commands>
#   a: Add files to archive
#   b: Benchmark
#   d: Delete files from archive
#   e: Extract files from archive (without using directory names)
#   l: List contents of archive
#   t: Test integrity of archive
#   u: Update files to archive
#   x: eXtract files with full paths
# <Switches>
#   -ai[r[-|0]]{@listfile|!wildcard}: Include archives
#   -ax[r[-|0]]{@listfile|!wildcard}: eXclude archives
#   -bd: Disable percentage indicator
#   -i[r[-|0]]{@listfile|!wildcard}: Include filenames
#   -m{Parameters}: set compression Method
#   -o{Directory}: set Output directory
#   -p{Password}: set Password
#   -r[-|0]: Recurse subdirectories
#   -scs{UTF-8 | WIN | DOS}: set charset for list files
#   -sfx[{name}]: Create SFX archive
#   -si[{name}]: read data from stdin
#   -slt: show technical information for l (List) command
#   -so: write data to stdout
#   -ssc[-]: set sensitive case mode
#   -ssw: compress shared files
#   -t{Type}: Set type of archive
#   -u[-][p#][q#][r#][x#][y#][z#][!newArchiveName]: Update options
#   -v{Size}[b|k|m|g]: Create volumes
#   -w[{path}]: assign Work directory. Empty path means a temporary directory
#   -x[r[-|0]]]{@listfile|!wildcard}: eXclude filenames
#   -y: assume Yes on all queries
#
#
##############################################################################

require 'ktutils/os'

module TorrentProcessor::Service

  class SevenZip

    def SevenZip.app_path=(path)
      @@app_path = path
    end

    def SevenZip.app_path
      return @@app_path unless (!defined?(@@app_path) || @@app_path.nil?)

      if Ktutils::OS.windows?
        possible_locations = ['C:/Program Files/7Zip/7z.exe',
                              'C:/Program Files/7-Zip/7z.exe',
                              'C:/Program Files (x86)/7Zip/7z.exe',
                              'C:/Program Files (x86)/7-Zip/7z.exe',
                              'C:/opt/bin/7Zip/7z.exe']

        possible_locations.each do |path|
          if File.exists?(path)
            @@app_path = path
            return @@app_path
          end
        end
      else
        path = `which 7z`.chomp
        if File.exists? path
          @@app_path = path
          return @@app_path
        end
      end
      raise 'SevenZip Error: Unable to find 7Zip executable.'
    end

    def SevenZip.default_commands
      commands =  'x'           # Extract files with full paths
    end

    def SevenZip.default_switches
      switches =  '-y'          # Assume Yes on all queries
      if Ktutils::OS.unix?
        switches << ' -r'
      end
      switches
    end

    def SevenZip.extract_rar(src_dir, out_dir, logger = nil)
      src_dir = to_os_path(src_dir)
      out_dir = to_os_path(out_dir)

      switches = SevenZip.default_switches
      switches << " -o#{SevenZip.quote(out_dir)}"

      if Ktutils::OS.unix?
        src_dir += '/*.rar' unless src_dir.end_with?('.rar')
      end
      cmd_line = "#{SevenZip.default_commands} #{switches} #{SevenZip.quote(src_dir)}"
      app_cmd = "#{SevenZip.quote(app_path)} #{cmd_line}"
      logger.log "Executing: #{app_cmd}" unless logger.nil?

      #result = Kernel.system("#{app_cmd}")
      # Using backticks so we can capture all stdout output
      result = `#{app_cmd}`
      unless result.include? 'Everything is Ok'
        logger.log ("    ERROR: #{app_path} failed. Command line it was called with: ".concat(app_cmd) ) unless logger.nil?
        if Ktutils::OS.unix?
          if result.include? 'Unsupported Method'
            logger.log("    (Unsupported Method) Install p7zip-rar package and try again")
            logger.log("    See http://www.aptgetlife.co.uk/7z-7zip-errors-with-unsupported-method-message/ for details.")
          end
        end
        return false
      end

      true
    end

    ###
    # Quote a string
    #
    # str:: String to apply quotes to
    #
    def SevenZip.quote(str)
      return "\"#{str}\""
    end

    ###
    # Convert file separators to OS specific separators
    #
    # str:: String to convert
    #
    def SevenZip.to_os_path(str)
      if Ktutils::OS.unix?
        return str.to_s.gsub("\\", '/')
      else
        return str.to_s.gsub('/', "\\")
      end
    end
  end # class SevenZip
end # module TorrentProcessor::Service
