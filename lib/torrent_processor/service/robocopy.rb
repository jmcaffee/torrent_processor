# encoding: utf-8
############################################################################
# File::    robocopy.rb
# Purpose:: Interface to windows Robocopy utility
#
# Author::    Jeff McAffee 2013-10-22
# Copyright:: Copyright (c) 2013, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

###
# Robocopy Return Codes
#  @see http://ss64.com/nt/robocopy-exit.html
#
# The return code from Robocopy is a bit map, defined as follows:
#
#     Hex   Decimal  Meaning if set
#     0x10  16       Serious error. Robocopy did not copy any files.
#                    Either a usage error or an error due to insufficient access privileges
#                    on the source or destination directories.
#
#     0x08   8       Some files or directories could not be copied
#                    (copy errors occurred and the retry limit was exceeded).
#                    Check these errors further.
#
#     0x04   4       Some Mismatched files or directories were detected.
#                    Examine the output log. Some housekeeping may be needed.
#
#     0x02   2       Some Extra files or directories were detected.
#                    Examine the output log for details.
#
#     0x01   1       One or more files were copied successfully (that is, new files have arrived).
#
#     0x00   0       No errors occurred, and no copying was done.
#                    The source and destination directory trees are completely synchronized.
#
###


module TorrentProcessor::Service

  class Robocopy

    def Robocopy.default_switches
      switches =  '/Z'          # Copy in restartable mode.
      switches << ' /R:0'       # 0 retries
      switches << ' /IPG:100'   # Inter-packet gap (ms)
    end

    def Robocopy.copy_file(src_dir, dest_dir, file, logger = NullLogger)
      # Do a straight system copy if running on unix (robocopy doesn't exist).
      if Ktutils::OS.unix?
        src_path = Pathname(posix_path(src_dir)) + file
        dest_path = Pathname(posix_path(dest_dir))
        dest_path.mkpath
        logger.log "Copying #{src_path} -> #{dest_dir}"
        begin
          FileUtils.cp src_path, dest_dir
          logger.log "  Copy completed."
          return true
        rescue SystemCallError => e
          Robocopy.log_output logger, '0', 'FileUtils.cp', "#{src_path}, #{dest_dir}", e.message
          return false
        end
      end

      src_dir = win_path(src_dir)
      dest_dir = win_path(dest_dir)

      app_path = "robocopy"
      switches = Robocopy.default_switches
      switches << " /LOG+:#{Robocopy.quote(File.join(src_dir,'robocopy.log'))}"  # Log data to file

      cmd_line = "#{Robocopy.quote(src_dir)} #{Robocopy.quote(dest_dir)} #{Robocopy.quote(win_path(file))}"
      app_cmd = "#{app_path} #{cmd_line} #{switches}"
      logger.log "Executing: #{app_cmd}\n" unless logger.nil?

      output = `#{app_cmd}`
      result = $?.exitstatus

      if result != 1
        Robocopy.log_output logger, result, app_path, app_cmd, output
        return false
      end

      true
    end

    ###
    # Copy a directory
    #
    def Robocopy.copy_dir(src_dir, dest_dir, copy_empty_dirs = true, logger = NullLogger)
      # Do a straight system copy if running on unix (robocopy doesn't exist).
      if Ktutils::OS.unix?
        src_path = Pathname(posix_path(src_dir))
        # We have to split the final dir name off or we end up with
        # some/dest/path/torrent_dir/torrent_dir after the copy.
        # Freakin robocopy REQUIRES the torrent_dir on the dest path or
        # it dumps the CONTENTS of the dir being copied into the dest dir
        # (ie. it doesn't create the dest dir).
        dest_path = Pathname(posix_path(dest_dir)).split[0]
        dest_path.mkpath
        logger.log "Copying #{src_path} -> #{dest_dir}"
        begin
          FileUtils.cp_r src_path, dest_dir
          logger.log "  Copy completed."
          return true
        rescue SystemCallError => e
          Robocopy.log_output logger, '0', 'FileUtils.cp', "#{src_path}, #{dest_dir}", e.message
          return false
        end
      end

      src_dir = win_path(src_dir)
      dest_dir = win_path(dest_dir)

      app_path = "robocopy"
      switches = Robocopy.default_switches
      switches << ' /E' if copy_empty_dirs    # Copy empty dirs
      switches << " /LOG+:#{Robocopy.quote(File.join(src_dir,'robocopy.log'))}"  # Log data to file

      cmd_line = "#{Robocopy.quote(src_dir)} #{Robocopy.quote(dest_dir)}"
      app_cmd = "#{app_path} #{cmd_line} #{switches}"
      logger.log "Executing: #{app_cmd}\n" unless logger.nil?

      output = `#{app_cmd}`
      result = $?.exitstatus

      if result != 1
        Robocopy.log_output logger, result, app_path, app_cmd, output
        return false
      end

      true
    end

    def Robocopy.log_output(logger, exit_status, app_path, app_cmd, output)
      return if logger.nil?

      logger.log ("\n    ERROR:  #{app_path} failed. Command line it was called with: ".concat(app_cmd) )
      logger.log ("    Exit Status:  #{exit_status}")
      logger.log ("\n    OUTPUT STARTS >>>")
      logger.log (output)
      logger.log ("    <<< OUTPUT ENDS\n")
    end

    ###
    # Quote a string
    #
    # str:: String to apply quotes to
    #
    def Robocopy.quote(str)
      return "\"#{str}\""
    end

    def Robocopy.posix_path path
      path.to_s.gsub(/\\/, "/")
    end

    def Robocopy.win_path path
      path.to_s.gsub(/\//, "\\")
    end
  end # class Robocopy
end # module TorrentProcessor::Service

