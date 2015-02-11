##############################################################################
# File::    unrar.rb
# Purpose:: Extract .rar archives using 7Zip
#
# Author::    Jeff McAffee 01/07/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'pathname'

module TorrentProcessor::Plugin

  class Unrar

    def Unrar.register_cmds
      { ".unrar"            => Command.new(Unrar, :cmd_unrar, "Un-rar an archive"),
        #"." => Command.new(TMDBPlugin, :, ""),
      }
    end

    ###
    # Strips a command off of a string.
    def cmd_arguments cmd, cmd_string
      args = cmd_string.gsub(cmd, '').strip
    end

    def cmd_unrar(args)
      parse_args args
      cmdtxt = cmd_arguments('.unrar', args[:cmd])

      if cmdtxt.nil? || cmdtxt.empty?
        log 'Error: path to directory or torrent ID expected'
        cmd_help
        # Return true to indicate we 'handled' the command.
        return true
      end

      id = text_to_id cmdtxt
      if id >= 0
        if unrar_torrent id
          delete_archive_files_from_id id
        end
      else
        if extract_archive cmdtxt, @logger
          delete_archive_files(cmdtxt)
        end
      end


      # Return true to indicate we 'handled' the command.
      true
    end

    def cmd_help
      log 'Unrar Commands'
      log
      log '.unrar [FILE_PATH or TORRENT_ID]'
      log '    Extracts file(s) from a .rar archive.'
      log '    Extracted files are placed in the directory the archive resides in.'
      log
    end

    def execute ctx_args, args
      parse_args ctx_args

      set_torrent_data args

      extract_rar destination_location
    end

  private

    def defaults
      { :logger           => ::NullLogger,
      }
    end

    def parse_args args
      args = defaults.merge(args)
      @logger   = args[:logger]   if args[:logger]
      @database = args[:database] if args[:database]
    end

    def log msg = ''
      @logger.log msg
    end

    def database
      @database
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

    def text_to_id id
      begin
        return Integer(id)
      rescue ArgumentError => e
        return -1
      end
    end

    def destination_location
      dir_helper = TorrentProcessor::Utility::DirHelper.new
      dest_path = dir_helper.destination torrent[:filedir], torrent[:filename], torrent[:label]
      #return File.join(final_directory, torrent[:filename])
    end

    def extract_rar dest_path
      rar = find_rar dest_path
      if rar.nil?
        log 'Skipping unrar attempt: No .rar archive in directory'
        return
      end

      unless extract_archive(rar, @logger) == true
        raise PluginError, 'Unrar failed'
      end

      delete_archive_files dest_path
    end

    ###
    # Find the first .rar file in provided path
    #
    # nested: recurse into child dirs when true
    # returns nil or path to .rar file
    #

    def find_rar dir_path, nested = true
      rars = []
      if Ktutils::OS.windows?
        # Dir won't work with windows separators, so force unix separators.
        dir_path.gsub!('\\','/')
      end

      if nested
        rars =  Dir[File.join(dir_path, '/**/*.r??')]
      else
        rars =  Dir[File.join(dir_path, '/*.r??')]
      end
      return nil unless rars.size > 0
      return rars.sort.first
    end

    ###
    # Find all .rar files in provided path
    #
    # nested: recurse into child dirs when true
    # returns array of .rar files (or empty array)
    #

    def find_rars dir_path, nested = true
      rars = []
      # Dir won't work with windows separators, so force unix separators.
      dir_path = to_posix_path(dir_path)

      if nested
        rars =  Dir[File.join(dir_path, '/**/*.r??')]
      else
        rars =  Dir[File.join(dir_path, '/*.r??')]
      end
      return rars.sort
    end

    def unrar_torrent id
      set_torrent_data database.find_torrent_by_id(id)
      path = destination_location
      extract_archive(path, @logger)
    end

    def extract_archive path, logger
      dest_dir = Pathname(path)
      # Strip the filename from path (if there's a filename)
      dest_dir = dest_dir.dirname unless dest_dir.extname.empty?

      TorrentProcessor::Service::SevenZip.extract_rar(path, dest_dir, logger)
    end

    def delete_archive_files_from_id id
      # Calculate the destination path
      set_torrent_data database.find_torrent_by_id(id)
      path = destination_location

      delete_archive_files path
    end

    def delete_archive_files path
      rars = find_rars to_posix_path(path)
      log "Deleting rar files from #{path}"

      rars.each do |rar|
        log "  rm #{rar}"
        FileUtils.rm rar
      end
    end

    ###
    # Convert windows file separators to posix
    #
    # str:: String to convert
    #
    def to_posix_path(str)
      return str.to_s.gsub("\\", '/')
    end
  end # class
end # module
