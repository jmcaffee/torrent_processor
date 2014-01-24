############################################################################
# File::    movie_mover.rb
# Purpose:: Move movies
#
# Author::    Jeff McAffee 2013-10-21
# Copyright:: Copyright (c) 2013, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'YAML'

module TorrentProcessor::Plugin

  class MovieMoverDetails

    def initialize(config_file)
      @yml_path = config_file
    end

    def defaults
      { title: '',
        year: '',
        src_file: '',
        target_file: '',
        destination_path: '',
      }
    end

    def write(cfg_hash)
      cfg_hash = defaults.merge(cfg_hash)

      open(@yml_path, 'w') { |f| YAML.dump(cfg_hash, f) }
    end

    def read
      cfg_hash = {}
      if File.exists?(@yml_path)
        open(@yml_path) { |f| cfg_hash = YAML.load(f) }
      end
      cfg_hash
    end
  end



  class MovieMover
    require_relative 'movie_db'

    DETAILS_FILE  = 'mover.details'
    LOCK_FILE     = 'mover.lock'
    COMPLETE_FILE = 'mover.completed'


    def initialize(args)
      @tag = 'MovieMover'
      parse_args args
    end

    def defaults
      {
        :logger     => NullLogger,
        :movie_db   => Runtime.service.moviedb
      }
    end

    def parse_args args
      args = defaults.merge(args)
      self.logger = args[:logger]   if args[:logger]
      self.db     = args[:movie_db] if args[:movie_db]
    end

    def db=(movie_db)
      @db = movie_db
    end

    def db
      @db
    end

    def logger=(logger_obj)
      @logger = logger_obj
    end

    def log msg = ''
      @logger.log msg
    end

    def within_time_frame start_time, stop_time
      start = Time.parse(start_time)
      stop = Time.parse(stop_time)
      now = Time.now
      if start >= now && now <= stop
        return true
      end
      false
    end

    def process(src_dir, dest_dir, start_time, stop_time)
      if start_time != -1 && stop_time != -1
        return unless within_time_frame(start_time, stop_time)
      end

      # Build list of directories to parse.
      dirs = Dir.glob(src_dir + '/*')
      dirs.delete_if { |d| !File.directory?(d) }

      #dirs.each do |d|
      #  puts "  " + d
      #end

      dirs.each { |d| create_details_file(d, dest_dir) }

      dirs.each { |d| process_dir(d) }

      dirs.each { |d| clean_dir(d) }
    end

    def create_details_file dir, dest_dir
      #puts "create_details_file[#{dir}, #{dest_dir}]"

      # No need to process the dir if we've already created the details file.
      return if details_file_exists? dir

      path = get_video_file(dir)
      path = Pathname.new path
      file = path.basename
      #puts "  video file: #{file}"

      movies = db.search_movie(file.to_s)
      title = movies[0].title
      year = db.get_year(movies[0].release_date)
      target_filename = to_filename(title, year, path.extname)
      dest_path = File.join(dest_dir, to_filename(title, year, ''))

      #puts "  video title: #{title}"
      #puts "  video year:  #{year}"
      #puts "  target file: #{target_filename}"

      details = { title: title,
                  year: year,
                  src_file: file.to_s,
                  target_file: target_filename,
                  destination_path: dest_path
                }

      unless (title.empty? || year.empty? || file.to_s.empty? || target_filename.empty?)
        MovieMoverDetails.new(details_file(dir)).write(details)
      end
    end

    def process_dir dir
      #puts "process_dir [#{dir}]"

      log "#{@tag}: Processing directory: #{dir}"

      # Can't process the dir if there's no details file.
      if !details_file_exists? dir
        log "    'details' file does not exist! Aborting processing of directory"
        return
      end

      # No need to process this dir if the lock file exists.
      # It's already been processed.
      if lock_file_exists? dir
        log "    lock file exists! Aborting processing of directory"
        return
      end

      details = MovieMoverDetails.new(details_file(dir)).read

      target_dir = details[:destination_path]
      target_file = details[:target_file]

      src_file = details[:src_file]
      src_path = Pathname.new File.join(dir, src_file)

      create_lock_file(dir)

      # Robocopy doesn't allow for changing the filename during the copy.
      # We'll rename the src file to the target file prior to the copy.
      target_path = Pathname.new File.join(dir, target_file)
      FileUtils.mv src_path, target_path

      if TorrentProcessor::Service::Robocopy.copy_file(dir, target_dir, target_file, @logger)
        create_process_complete_file(dir)
      else
        # The copy failed. Rename the file back to the original for the next attempt.
        FileUtils.mv target_path, src_path
      end

      delete_lock_file(dir)
    end

    def clean_dir dir
      #puts "clean_dir [#{dir}]"
      log "#{@tag}: Cleaning directory: #{dir}"

      pc_file = File.join(dir, COMPLETE_FILE)

      # Can't clean the dir if there's no 'completed' file.
      if !File.exist?(pc_file)
        log "    'completed' file does not exist! Aborting cleaning of directory"
        return
      end

      if dir.nil? || dir.empty? || dir == '..' || dir == '..' || dir == '/'
        log "    invalid directory! Aborting cleaning of directory"
        return
      end

      if !File.exists?(dir) && File.directory?(dir)
        log "    directory does not exist! Aborting cleaning of directory"
        return
      end

      FileUtils.remove_dir(dir)
    end

    def details_file dir
      file = File.join(dir, DETAILS_FILE)
    end

    def details_file_exists? dir
      file = File.join(dir, DETAILS_FILE)
      File.exists? file
    end

    def create_lock_file dir
      #puts "create_lock_file [#{dir}]"
      file = File.join(dir, LOCK_FILE)
      FileUtils.touch file
    end

    def delete_lock_file dir
      #puts "delete_lock_file [#{dir}]"
      file = File.join(dir, LOCK_FILE)
      FileUtils.remove_file file
    end

    def lock_file_exists? dir
      file = File.join(dir, LOCK_FILE)
      File.exists? file
    end

    def create_process_complete_file dir
      #puts "create_process_complete_file [#{dir}]"
      file = File.join(dir, COMPLETE_FILE)
      FileUtils.touch file
    end

    def completed_file_exists? dir
      file = File.join(dir, COMPLETE_FILE)
      File.exists? file
    end

    def to_filename(title, year, ext)
      title_text = title.gsub('&', 'and')
      title_text.gsub!('/', ' ')
      title_text.gsub!('\\', ' ')
      title_text.gsub!(':', ' ')
      title_text.gsub!('?', ' ')
      title_text.gsub!('*', ' ')
      title_text.gsub!(' ', '.')
      title_text << ".(#{year})" << ext
      title_text.gsub! /\.+/, '.'
    end

    def get_video_file(search_dir)
      return nil unless File.exist?(search_dir) && File.directory?(search_dir)

      # Build a file glob that looks like "somedir/**/*{.avi,.mkv}"
      files = Dir.glob("#{search_dir}/**/*#{file_extension_glob}")
      maxsize = 0
      filename = ''
      files.each do |f|
        pn = Pathname.new(f)
        if pn.size > maxsize
          maxsize = pn.size
          filename = f
        end
        #puts f + ": " + Pathname.new(f).size.to_s
      end
      filename
    end

    def file_extension_glob
      glob = ''
      glob = MovieDB::EXT_TYPES.join(',')
      glob.prepend('{')
      glob << '}'
    end
  end # class MovieMover
end # module TorrentProcessor::Plugin
