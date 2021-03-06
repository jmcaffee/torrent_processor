##############################################################################
# File::    dir_helper.rb
# Purpose:: Logic to determine the destination directory of a torrent.
#
# Author::    Jeff McAffee 01/28/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

module TorrentProcessor::Utility
  class DirHelper

    def initialize args = {}
      parse_args args
    end

    def defaults
      {
        :tv_processing    => TorrentProcessor.configuration.tv_processing,
        :movie_processing => TorrentProcessor.configuration.movie_processing,
        :other_processing => TorrentProcessor.configuration.other_processing,
        :download_dir     => TorrentProcessor.configuration.dir_completed_download,
      }
    end

    def parse_args args
      args = defaults.merge(args)
      @tv_processing    = String(args[:tv_processing])    if args[:tv_processing]
      @movie_processing = String(args[:movie_processing]) if args[:movie_processing]
      @other_processing = String(args[:other_processing]) if args[:other_processing]
      @download_dir     = String(args[:download_dir])     if args[:download_dir]
    end

    def subdirectory?
      @is_subdir
    end

    def subdirectory
      @subdirectory
    end

    def destination(current_dir, torrent_name, label)
      current_dir = String(current_dir)
      target_dir = final_directory(label)

      subdir = subdirectory_of(@download_dir, current_dir)
      if ! subdir.nil? && ! subdir.empty?
        @is_subdir = true
        @subdirectory = subdir
      else
        @is_subdir = false
        @subdirectory = nil
      end

      if @is_subdir
        target_dir
      else
        File.join(target_dir, torrent_name)
      end
    end

  private

    def final_directory label
      dest_path = @other_processing
      dest_path = @tv_processing     if (label.downcase.include?("tv"))
      dest_path = @movie_processing  if (label.downcase.include?("movie"))
      dest_path
    end

    def subdirectory_of download_dir, current_dir
      if (current_dir != download_dir)
        path_tail = current_dir.split(download_dir)[1]
        path_tail = path_tail.prepend('/') unless path_tail.nil? || path_tail.start_with?('/')
        return path_tail
      end
      ''
    end
  end
end
