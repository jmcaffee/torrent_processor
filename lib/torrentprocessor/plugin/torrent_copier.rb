##############################################################################
# File::    torrent_copier.rb
# Purpose:: Processor plugin to copy downloaded torrents
#
# Author::    Jeff McAffee 01/06/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################


module TorrentProcessor::Plugin

  class TorrentCopier
    require_relative '../service/robocopy'

    def execute ctx, args
      @context = ctx
      set_torrent_data args

      # Throw exception if torrent hasn't completed the download.

      verify_torrent_in_completed_download_dir

      # Setup the destination processing folder path.

      dest_path = final_directory

      # Modify destination path if torrent is in subdirectory.

      path_tail = torrent_subdir
      is_subdir = (path_tail.nil? ? false : true)
      dest_path += path_tail if is_subdir

      # Copy the torrent.

      copy_torrent dest_path, is_subdir

      # Verify copy was successful.

      target_path = "#{dest_path}\\#{torrent[:filename]}"
      target_path = "#{dest_path}" if is_subdir
      verify_successful_copy target_path
    end

  private

    def context
      @context
    end

    def log msg = ''
      if context.respond_to? :log
        context.log msg
      elsif context.respond_to? :logger
        context.logger.log msg
      else
        puts msg
      end
    end

    def cfg
      context.cfg
    end

    def default_args
      {hash: nil, filename: nil, filedir: '', label: ''}
    end

    def set_torrent_data args
      @torrent = default_args.merge(args)
    end

    def torrent
      @torrent
    end

    def final_directory
      dest_path = cfg[:otherprocessing]
      dest_path = cfg[:tvprocessing]     if (torrent[:label].include?("TV"))
      dest_path = cfg[:movieprocessing]  if (torrent[:label].include?("Movie"))
      dest_path
    end

    def completed_dir
      TorrentProcessor.configuration.utorrent.dir_completed_download
    end

    def torrent_subdir
      if (torrent[:filedir] != completed_dir)
        is_subdir = true
        path_tail = torrent[:filedir].split(completed_dir)[1]
        path_tail = path_tail.prepend('/') unless path_tail.start_with?('/')
        return path_tail
      end
    end

    def copy_torrent dest_path, is_dir
      if is_dir
        TorrentProcessor::Service::Robocopy.copy_dir(torrent[:filedir], dest_path, true, context.logger)
      else
        TorrentProcessor::Service::Robocopy.copy_file(torrent[:filedir], dest_path, torrent[:filename], context.logger)
      end # if
    end

    def verify_torrent_in_completed_download_dir
      if (!torrent[:filedir].include?( completed_dir ))
        log("    ERROR: Downloaded Torrent is not in the expected location.")
        log("           Torrent location: #{torrent[:filedir]}")
        log("           Expected location: #{completed_dir} -- or a subdirectory of this location.")
        log("    Copy operation will be attempted later.")
        raise PluginError, 'Torrent download not yet completed'
      end
    end

    def verify_successful_copy target_path
      if( !File.exists?(target_path) )
        log ("    ERROR: Unable to verify that target exists. Target path: #{target_path}")
        raise PluginError, 'Torrent copy failed'
      end
    end
  end # class
end # module

