# TorrentProcessor dependencies
source "https://rubygems.org"

gem "nokogiri"
gem "hoe", ">=1.3"
gem "json"
gem "ktcommon", :git => 'git@bitbucket.org:ktechsystems/ktcommon.git'
gem "ktutils"#,  :git => 'git@github.com:jmcaffee/ktutils.git'
gem "qbt_client"
gem "s4t-utils"
gem "sqlite3",      :platforms => [:ruby, :mswin, :mingw]
gem "dbi",          :platforms => :jruby
gem "dbd-jdbc",     :platforms => :jruby
gem "jdbc-sqlite3", :platforms => :jruby
gem "sequel",       :platforms => :jruby
gem "user-choices"
gem "xml-simple"
gem "themoviedb"

group :development do
  gem 'puck',       ">=1.0.0.pre",  :require => false
  gem 'jruby-jars', "= 1.7.18",     :require => false

  gem 'rdoc',               :require => false
  gem 'guard',              :require => false
  gem 'guard-rspec',        :require => false
  gem 'pry',                :require => false
  gem 'pry-nav',            :require => false
  gem 'pry-rescue',         :require => false
  gem 'pry-stack_explorer', :require => false, :platforms => [:ruby, :mswin, :mingw]
  gem 'rb-readline',        :require => false
end

group :test do
  gem 'rspec'
  gem 'rspec-its'
  gem 'simplecov',          :require => false
end
