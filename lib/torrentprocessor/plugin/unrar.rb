##############################################################################
# File::    unrar.rb
# Purpose:: Extract .rar archives using 7Zip
#
# Author::    Jeff McAffee 01/07/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

module TorrentProcessor::Plugin

  class Unrar

    def Unrar.register_cmds
      { ".unrar"            => Command.new(Unrar, :cmd_unrar, "Un-rar an archive"),
        #".tmdbmoviesearch"  => Command.new(Unrar, :search_movie,       "Search for a movie"),
        #"." => Command.new(IMDBPlugin, :, ""),
      }
    end

    def cmd_unrar(args)
      cmdtxt  = args[0]
      @context  = args[1]

      raise 'Unrar: Caller object must be provided as second element of argument array' if context.nil?

      if cmdtxt.nil?
        log 'Error: path to directory or torrent ID expected'
        cmd_help
        return
      end

      id = text_to_id cmdtxt
      if id >= 0
        unrar_torrent id
      else
        unrar_path cmdtxt
      end
    end

    def cmd_help
      log 'Unrar Commands'
      log
      log '.unrar [FILE_PATH or TORRENT_ID]'
      log '    Extracts file(s) from a .rar archive.'
      log '    Extracted files are placed in the directory the archive resides in.'
      log
    end

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

      extract_rar dest_path, is_subdir
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

    def database
      context.database
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

    def text_to_id id
      begin
        return Integer(id)
      rescue ArgumentError => e
        return -1
      end
    end

    def destination_location
      return File.join(final_directory, torrent[:filename])
    end

    def extract_rar dest_path, is_dir
      unless is_dir
        log 'Skipping unrar attempt: Torrent not in subdirectory'
        return
      end

      unless (Dir[File.join(dest_path, '*.rar')].size > 0)
        log 'Skipping unrar attempt: No .rar archive in directory'
        return
      end

      unless unrar_path(dest_path) == true
        raise PluginError, 'Unrar failed'
      end
    end

    def unrar_path path
      TorrentProcessor::Service::SevenZip.extract_rar(path, path, context.logger)
    end

    def unrar_torrent id
      set_torrent_data database.find_torrent_by_id(id)
      path = destination_location
      TorrentProcessor::Service::SevenZip.extract_rar(path, path, context.logger)
    end
  end # class
end # module
