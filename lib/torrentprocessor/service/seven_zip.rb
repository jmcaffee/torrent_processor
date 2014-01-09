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


module TorrentProcessor::Plugin

  class SevenZip

    def SevenZip.app_path=(path)
      @@app_path = path
    end

    def SevenZip.app_path
      return @@app_path unless (!defined?(@@app_path) || @@app_path.nil?)

      possible_locations = ['C:/Program Files/7Zip/7z.exe',
                            'C:/Program Files (x86)/7Zip/7z.exe',
                            'C:/opt/bin/7Zip/7z.exe']

      possible_locations.each do |path|
        if File.exists?(path)
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
    end

    def SevenZip.extract_rar(src_dir, out_dir, logger = nil)
      switches = SevenZip.default_switches
      switches << " -o#{out_dir}"

      cmd_line = "#{SevenZip.default_commands} #{switches} #{SevenZip.quote(src_dir)}"
      app_cmd = "#{app_path} #{cmd_line}"
      logger.log "Executing: #{app_cmd}" unless logger.nil?

      result = Kernel.system("#{app_cmd}")
      unless result
          logger.log ("    ERROR: #{app_path} failed. Command line it was called with: ".concat(app_cmd) ) unless logger.nil?
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
  end # class SevenZip
end # module TorrentProcessor::Plugin
