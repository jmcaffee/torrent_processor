##############################################################################
# File::    torrent_copier_plugin.rb
# Purpose:: Processor plugin to copy downloaded torrents
#
# Author::    Jeff McAffee 01/06/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

module TorrentProcessor::ProcessorPlugin

  class TorrentCopierPlugin

    def context
      @context
    end

    def log
      context.log
    end

    def cfg
      context.cfg
    end

    def default_args
      {hash: nil, filename: nil, filedir: nil, label: nil}
    end

    def execute ctx, args
      @context = ctx
      torrent = default_args.merge(args)

      # Setup the destination processing folder path.
      dest_path = cfg[:otherprocessing]
      dest_path = cfg[:tvprocessing]     if (torrent[:label].include?("TV"))
      dest_path = cfg[:movieprocessing]  if (torrent[:label].include?("Movie"))

      # Handle situation where the torrent is in a subfolder.
      path_tail = ""
      #cmdLineSwitch = ""
      is_subdir = false

      if (!torrent[:filedir].include?( @dir_completed_download ))
        log("    ERROR: Downloaded Torrent is not in the expected location.")
        log("           Torrent location: #{torrent[:filedir]}")
        log("           Expected location: #{@dir_completed_download} -- or a subdirectory of this location.")
        log("    Copy operation will be attempted later.")
        return false
      end

      if (torrent[:filedir] != @dir_completed_download)
        is_subdir = true
        path_tail = torrent[:filedir].split(@dir_completed_download)[1]
        path_tail = path_tail.prepend('/') unless path_tail.start_with?('/')
      end

      dest_path += path_tail

      if is_subdir
        Robocopy.copy_dir(torrent[:filedir], dest_path, true, context)
      else
        Robocopy.copy_file(torrent[:filedir], dest_path, torrent[:filename], context)
      end # if

      target_path = "#{dest_path}\\#{torrent[:filename]}"
      target_path = "#{dest_path}" unless !is_subdir
      if( !File.exists?(target_path) )
          log ("    ERROR: Unable to verify that target exists. Target path: #{target_path}")
          return false
      end

      return true
    end
  end # class
end # module

