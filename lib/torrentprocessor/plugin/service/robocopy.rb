############################################################################
# File::    robocopy.rb
# Purpose:: Interface to windows Robocopy utility
#
# Author::    Jeff McAffee 2013-10-22
# Copyright:: Copyright (c) 2013, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

module TorrentProcessor::Service

  class Robocopy

    def Robocopy.default_switches
      switches =  '/Z'          # Copy in restartable mode.
      switches << ' /R:0'       # 0 retries
      switches << ' /IPG:100'   # Inter-packet gap (ms)
    end

    def Robocopy.copy_file(src_dir, dest_dir, file, logger = nil)
      app_path = "robocopy"
      switches = Robocopy.default_switches
      switches << " /LOG+:#{Robocopy.quote(File.join(src_dir,'robocopy.log'))}"  # Log data to file

      cmd_line = "#{Robocopy.quote(src_dir)} #{Robocopy.quote(dest_dir)} #{Robocopy.quote(file)}"
      app_cmd = "#{app_path} #{cmd_line} #{switches}"
      logger.log "Executing: #{app_cmd}" unless logger.nil?

      result = Kernel.system("#{app_cmd}")
      if result
          logger.log ("    ERROR: #{app_path} failed. Command line it was called with: ".concat(app_cmd) ) unless logger.nil?
          return false
      end
      true
    end

    ###
    # Copy a directory
    #
    def Robocopy.copy_dir(src_dir, dest_dir, copy_empty_dirs = true, logger = nil)
      app_path = "robocopy"
      switches = Robocopy.default_switches
      switches << ' /E' if copy_empty_dirs    # Copy empty dirs
      switches << " /LOG+:#{Robocopy.quote(File.join(src_dir,'robocopy.log'))}"  # Log data to file

      cmd_line = "#{Robocopy.quote(src_dir)} #{Robocopy.quote(dest_dir)}"
      app_cmd = "#{app_path} #{cmd_line} #{switches}"
      logger.log "Executing: #{app_cmd}" unless logger.nil?

      result = Kernel.system("#{app_cmd}")
      if result
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
    def Robocopy.quote(str)
      return "\"#{str}\""
    end
  end # class Robocopy
end # module TorrentProcessor::Service
