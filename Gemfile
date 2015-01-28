# TorrentProcessor dependencies
source "https://rubygems.org"

gem "hpricot"
gem "hoe", ">=1.3"
gem "json"
gem "ktcommon", :git => 'git@bitbucket.org:ktechsystems/ktcommon.git'
gem "ktutils",  :git => 'git@github.com:jmcaffee/ktutils.git'
gem "s4t-utils"
gem "sqlite3",      :platforms => [:ruby, :mswin, :mingw]
gem "dbi",          :platforms => :jruby
gem "dbd-jdbc",     :platforms => :jruby
gem "jdbc-sqlite3", :platforms => :jruby
gem "user-choices"
gem "xml-simple"
gem "themoviedb"

group :development do
  gem 'warbler',            :require => false
  gem 'pry',                :require => false
  gem 'pry-nav',            :require => false
  gem 'pry-rescue',         :require => false
  gem 'pry-stack_explorer', :require => false, :platforms => [:ruby, :mswin, :mingw]
  gem 'rb-readline',        :require => false
end

group :test do
  gem 'rspec'
  gem 'simplecov',          :require => false
end
