##############################################################################
# File::    unrar_plugin.rb
# Purpose:: UnrarPlugin
#
# Author::    Jeff McAffee 01/07/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

module TorrentProcessor::ProcessorPlugin

  class UnrarPlugin

    def execute ctx, args
      @context = ctx
      set_torrent_data args

      # Setup the destination processing folder path.

      dest_path = final_directory

      # Modify destination path if torrent is in subdirectory.

      path_tail = torrent_subdir
      is_subdir = (path_tail.nil? ? false : true)
      dest_path += path_tail if is_subdir

      # Extract the torrent.

      unrar_torrent dest_path, is_subdir
    end

  private

    def context
      @context
    end

    def log msg
      context.log msg
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

    def unrar_torrent dest_path, is_dir
      unless is_dir
        log 'Skipping unrar attempt: Torrent not in subdirectory'
        return
      end

      unless (Dir[File.join(dest_path, '*.rar')].size > 0)
        log 'Skipping unrar attempt: No .rar archive in directory'
        return
      end

      unless SevenZip.extract_rar(dest_path, dest_path, context) == true
        raise 'Unrar failed'
      end
    end
  end # class
end # module
