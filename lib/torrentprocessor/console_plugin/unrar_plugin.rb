##############################################################################
# File::    unrar_plugin.rb
# Purpose:: UnrarPlugin (console) class
#
# Author::    Jeff McAffee 01/08/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

module TorrentProcessor::ConsolePlugin

  class UnrarPlugin

    def UnrarPlugin.register_cmds
      { ".unrar"            => Command.new(UnrarPlugin, :unrar,         "Un-rar an archive"),
        #".tmdbmoviesearch"  => Command.new(UnrarPlugin, :search_movie,       "Search for a movie"),
        #"." => Command.new(IMDBPlugin, :, ""),
      }
    end

    def initialize
      @tag = 'UnrarPlugin'
    end

    def unrar(args)
      cmdtxt  = args[0]
      @kaller  = args[1]

      raise 'UnrarPlugin: Caller object must be provided as second element of argument array' if kaller.nil?

      if cmdtxt.nil?
        log 'Error: path to directory or torrent ID expected'
        help
        return
      end

      id = text_to_id cmdtxt
      if id >= 0
        unrar_torrent id
      else
        unrar_path cmdtxt
      end
    end

    def help
      log 'Unrar Commands'
      log
      log '.unrar [FILE_PATH or TORRENT_ID]'
      log '    Extracts file(s) from a .rar archive.'
      log '    Extracted files are placed in the directory the archive resides in.'
      log
    end

  private

    def kaller
      @kaller
    end

    def cfg
      kaller.cfg
    end

    def database
      kaller.database
    end

    def log msg = ''
      if kaller.respond_to? :log
        kaller.log msg
      elsif kaller.respond_to? :logger
        kaller.logger.log msg
      else
        puts msg
      end
    end

    def text_to_id id
      begin
        return Integer(id)
      rescue ArgumentError => e
        return -1
      end
    end

    def unrar_path path
      TorrentProcessor::ProcessorPlugin::SevenZip.extract_rar(path, path, nil)
    end

    def unrar_torrent id
      torrent = database.find_torrent_by_id(id)
      path = destination_location torrent
      TorrentProcessor::ProcessorPlugin::SevenZip.extract_rar(path, path, nil)
    end

    def final_directory torrent
      dest_path = cfg[:otherprocessing]
      dest_path = cfg[:tvprocessing]     if (torrent[:label].include?("TV"))
      dest_path = cfg[:movieprocessing]  if (torrent[:label].include?("Movie"))
      dest_path
    end

    def destination_location torrent
      return File.join(final_directory(torrent), torrent[:filename])
    end
  end # class UnrarPlugin
end # module
