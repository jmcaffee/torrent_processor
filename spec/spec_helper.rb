require 'simplecov'
SimpleCov.start

# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# Require this file using `require "spec_helper"` to ensure that it is only
# loaded once.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
  config.order = 59885
end

include FileUtils

def create_file_of_size(file_path, file_size, random = false)
  # Create the directory path if it doesn't exist.
  tmp = '-tmp'
  pn = Pathname.new(file_path + tmp)
  dir = pn.dirname
  if !dir.exist?
    dir.mkpath
  end

  # Delete the existing file if needed.
  pn = Pathname.new(file_path)
  if pn.exist?
    pn.delete
  end

  # Write a file to disk.
  File.open(file_path + tmp, 'w') do |f|
    if random
      file_size.times do
        f.write Random.rand(10)
      end
    else
      f.write '1'*file_size
    end
    f.flush
  end

  mv(file_path + tmp, file_path)
end

def generate_movie_set(root_dir, movie_name, movie_ext)
  root = Pathname.new(root_dir)
  root = root + movie_name
  movie = root
  movie += movie_name + movie_ext

  sample = root
  sample += movie_name + '(sample)' + movie_ext

  nfo = root
  nfo += movie_name + '.nfo'

  create_file_of_size(movie.to_s, 22000)
  create_file_of_size(sample.to_s, 10000)
  create_file_of_size(nfo.to_s, 2000)

  # Return the created dir
  root.to_s
end

def blocking_dir_delete(path)
  return unless (File.exists?(path) && File.directory?(path))

  max_trys = 2000
  trys = 0
  while File.exists?(path)
    if trys > max_trys
      puts "You must be on WinBLOWS!"
      puts "Unable to delete #{path} after #{max_trys} trys"
      return
    end
    begin
      FileUtils.rm_r path
    rescue Errno::EACCES => e
      trys += 1
    end
  end
end

def blocking_file_delete(path)
  return unless (File.exists?(path) && !File.directory?(path))

  max_trys = 2000
  trys = 0
  while File.exists?(path)
    if trys > max_trys
      puts "You must be on WinBLOWS!"
      puts "Unable to delete #{path} after #{max_trys} trys"
      return
    end
    begin
      FileUtils.rm path
    rescue Errno::EACCES => e
      trys += 1
    rescue Errno::ENOENT => e
      # File doesn't exist? WTF?
      return
    end
  end
end

def create_downloaded_torrent(src, destdir)
  if ! File.exists? src
    raise '!!! spec_helper::create_downloaded_torrent #{src} does not exist'
  end

  mkdir_p destdir

  if File.directory? src
    cp_r src, destdir
    return
  end

  cp src, destdir
end

class NullLogger
  def NullLogger.log msg = ''
  end

  def NullLogger.log_dir dir
  end
end

class SimpleLogger < NullLogger
  def SimpleLogger.log msg = ''
    puts msg
  end
end

class CaptureLogger < NullLogger

  def CaptureLogger.log msg = ''
    messages << msg if !msg.nil? && !msg.empty?
  end

  def CaptureLogger.messages
    @messages ||= []
  end

  def CaptureLogger.reset
    @messages = []
  end

  def CaptureLogger.dump_messages
    messages.each { |m| puts m }
  end

  def CaptureLogger.contains text
    messages.each do |m|
      return true if m.include?(text)
    end
    msgs = ''
    messages.each { |m| msgs << m + "\n" }
    raise "'#{text}' not found in:\n#{msgs}"
  end

  def CaptureLogger.does_not_contain text
    messages.each do |m|
      raise "'#{text}' found in:\n#{m}" if m.include?(text)
    end
    true
  end
end

def generate_configuration dir_name, &block
  cfg_file = File.join(dir_name, 'config.yml')

  rm cfg_file if File.exists? cfg_file
  cp 'spec/data/new_config.yml', cfg_file
  TorrentProcessor.load_configuration cfg_file

  if block_given?
    TorrentProcessor.configure &block
  else
    TorrentProcessor.configure do |config|
      config.app_path                 = dir_name
      config.log_dir                  = dir_name
      config.tv_processing            = File.join(dir_name, 'tv')
      config.movie_processing         = File.join(dir_name, 'movie')
      config.other_processing         = File.join(dir_name, 'other')
      config.utorrent.dir_completed_download  = File.join(dir_name, 'completed')
      config.tmdb.target_movies_path            = File.join(dir_name, 'final_movies')

      mkpath config.tv_processing
      mkpath config.movie_processing
      mkpath config.other_processing
      mkpath config.utorrent.dir_completed_download
      mkpath config.tmdb.target_movies_path
    end
    TorrentProcessor.save_configuration
  end
end

require_relative 'support/dirs'
require_relative 'support/files'
require_relative 'support/database_helper'

require_relative '../lib/torrentprocessor'
require_relative '../lib/torrentprocessor/service/seven_zip'
