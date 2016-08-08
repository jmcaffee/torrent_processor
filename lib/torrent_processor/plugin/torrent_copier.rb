##############################################################################
# File::    torrent_copier.rb
# Purpose:: Processor plugin to copy downloaded torrents
#
# Author::    Jeff McAffee 01/06/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################


module TorrentProcessor
  module Plugin

  class TorrentCopier < BasePlugin

    attr_reader :other_processing
    attr_reader :tv_processing
    attr_reader :movie_processing
    attr_reader :torrent
    attr_reader :completed_dir


    def execute args, torrent_data
      parse_args args
      set_torrent_data torrent_data

      # Throw exception if torrent hasn't completed the download.

      verify_torrent_in_completed_download_dir

      # Setup the destination processing folder path.

      dir_helper = TorrentProcessor::Utility::DirHelper.new(
        {
          :download_dir     => completed_dir,
          :tv_processing    => tv_processing,
          :movie_processing => movie_processing,
          :other_processing => other_processing,
          :logger           => logger
        })

      # qbtorrent returns the 'completed downloads' dir in torrent[:filedir]
      # and the torrent[:filename] will be the folder name.
      #
      # Check to see if the path (completed_downloads/filedir) is a directory.
      # If it is, pass it in as the torrent_dir instead of just the 'completed
      # downloads' dir.
      #
      # This should result in dir_helper returning TRUE for the subdir?
      #
      torrent_dir = Pathname(torrent[:filedir])
      potential_dir = torrent_dir + torrent[:filename]
      if potential_dir.exist? && potential_dir.directory?
        torrent[:filedir] = potential_dir
      end

      dest_path = dir_helper.destination torrent[:filedir], torrent[:filename], torrent[:label]

      # Copy the torrent.

      copy_torrent dest_path, dir_helper.subdirectory

      # Verify copy was successful.

      target_path = File.join(dest_path, torrent[:filename])
      target_path = "#{dest_path}" if dir_helper.subdirectory?
      verify_successful_copy target_path
    end

    protected

    def parse_args args
      super

      @completed_dir    = args[:completed_dir]      if args[:completed_dir]
      @other_processing = args[:other_processing]   if args[:other_processing]
      @tv_processing    = args[:tv_processing]      if args[:tv_processing]
      @movie_processing = args[:movie_processing]   if args[:movie_processing]

      @completed_dir    ||= cfg.dir_completed_download
      @other_processing ||= cfg.other_processing
      @tv_processing    ||= cfg.tv_processing
      @movie_processing ||= cfg.movie_processing
    end

    def defaults
      { :logger           => ::NullLogger,
        #:completed_dir    => cfg.dir_completed_download,
        #:other_processing => cfg.other_processing,
        #:tv_processing    => cfg.tv_processing,
        #:movie_processing => cfg.movie_processing,
      }
    end

    private

    def default_torrent_args
      {hash: nil, filename: nil, filedir: '', label: ''}
    end

    def set_torrent_data args
      @torrent = default_torrent_args.merge(args)
    end

    def copy_torrent dest_path, subdir
      if subdir.nil?
        TorrentProcessor::Service::Robocopy.copy_file(torrent[:filedir], dest_path, torrent[:filename], @logger)
      else
        dest_path = File.join(dest_path, subdir)
        TorrentProcessor::Service::Robocopy.copy_dir(torrent[:filedir], dest_path, true, @logger)
      end # if
    end

    def verify_torrent_in_completed_download_dir
      tmp_completed_dir = completed_dir
      tmp_file_dir = torrent[:filedir]

      log '#'*40
      log torrent.inspect
      log "completed_dir: #{tmp_completed_dir}"
      if (!tmp_file_dir.include?( tmp_completed_dir ))
        log("    ERROR: Downloaded Torrent is not in the expected location.")
        log("           Torrent location: #{tmp_file_dir}")
        log("           Expected location: #{tmp_completed_dir} -- or a subdirectory of this location.")
        log("    Copy operation will be attempted later.")
        raise PluginError, 'Torrent download not yet completed'
      end
    end

    def verify_successful_copy target_path
      tmp_target_path = target_path
      if( !File.exists?(tmp_target_path) )
        log ("    ERROR: Unable to verify that target exists. Target path: #{tmp_target_path}")
        raise PluginError, 'Torrent copy failed'
      end
    end
  end # class
  end # module
end # module

