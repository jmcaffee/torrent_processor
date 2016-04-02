##############################################################################
# File::    files.rb
# Purpose:: Spec file helper methods
# 
# Author::    Jeff McAffee 2015-02-02
# Copyright:: Copyright (c) 2015, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

def tab num
  ' '*num
end

def spec_dbg msg
  puts '+ ' + msg.to_s
end

def wait_for_file filename
  tries = 0
  max_tries = 5

  while !filename.size? && tries < max_tries
    sleep 1
    tries += 1
  end
end

def create_rar_file dest_dir
  dest_dir = Pathname(dest_dir)
  src = spec_data_dir + 'multi_rar/*.rar'
  files = Dir[src]
  dest_dir.mkpath unless dest_dir.exist?

  files.each do |f|
    cp f, dest_dir
  end

  last_file = Pathname(dest_dir) + Pathname(files.last).basename
  wait_for_file last_file

  spec_dbg "Created multi_rar archive in #{dest_dir}"
  dest_dir
end

def create_old_style_rar_file dest_dir
  src = spec_data_dir + 'old_style_rar/*.r??'
  cp src, dest_dir
end

def in_file? search_str, file
  found = false
  File.read(file).each_line do |line|
    return true if line.include? search_str
  end
  false
end
