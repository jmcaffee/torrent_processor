##############################################################################
# File::    loggers.rb
# Purpose:: Logging classes
# 
# Author::    Jeff McAffee 01/11/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

class NullLogger
  def self.log msg = ''
  end
end


class ScreenLogger
  def self.log msg = ''
    puts msg
  end
end


class FileLogger

  def self.logdir=(log_dir_name)
    @logdir = log_dir_name
  end

  def self.logdir
    @logdir ||= '.'
  end

  def self.logfile=(filename)
    @logfile = filename
  end

  def self.logfile
    @logfile ||= 'torrentprocessor.log'
  end

  def self.logpath
    File.join(logdir, logfile)
  end

  def self.max_log_size=(max_size_in_bytes)
    @max_log_size = max_size_in_bytes
  end

  def self.max_log_size
    @max_log_size ||= 1024 * 500
  end

  def self.log msg = nil
    return if msg.nil?

    rotate_log
    timestamp = DateTime.now.strftime()

    File.open(logpath, 'a') { |f| f.write( "#{timestamp}: #{msg}\n"); f.flush; }
  end

  def self.rotate_log
    return if max_log_size == 0

    if FileTest.size(logpath) > max_log_size

      # Used to determine if a file was still open when receiving EACCESS errors.
      #puts "#"*20
      #ObjectSpace.each_object(File) { |f| p f if f.path.include?(logpath) && !f.closed? }
      #puts "#"*20

      FileUtils.rm(logpath + '.3') if File.exists?(logpath + '.3')
      FileUtils.mv(logpath + '.2', logpath + '.3') if File.exists?(logpath + '.2')
      FileUtils.mv(logpath + '.1', logpath + '.2') if File.exists?(logpath + '.1')
      FileUtils.mv(logpath, logpath + '.1') if File.exists?(logpath)
    end # if
  end
end

