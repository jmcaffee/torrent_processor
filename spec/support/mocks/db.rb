require 'rspec/mocks/standalone'

module Mocks

  def self.db_instance
    db = instance_double('TorrentProcessor::Database')
  end

  def self.db
    obj = double('database')
    allow(obj).to receive(:connect)  { true }
    allow(obj).to receive(:close)    { true }
    allow(obj).to receive(:execute) do |q|
      if q.include? 'SELECT hash FROM torrents'
        [
          [ 'abc' ]
        ]
      elsif q.include? 'SELECT hash, name FROM torrents WHERE (tp_state IS NULL AND id = 2)'
        [
          [ 'abc', 'TestTorrent1' ]
        ]
      elsif q.include? 'SELECT id,ratio,name from torrents'
        [
          [ 2, 1500, 'TestTorrent1' ]
        ]
      elsif q.include? 'SELECT id,tp_state,name from torrents'
        [
          [ 2, 'removing', 'TestTorrent1' ]
        ]
      elsif q.include? "SELECT name from sqlite_master WHERE type = 'table' ORDER BY name"
        [
          [ 'torrents' ]
        ]
      else
        []
      end
    end
    allow(obj).to receive(:read) do |q|
      if q.include? 'SELECT hash FROM torrents'
        [
          [ 'abc' ]
        ]
      elsif q.include? 'SELECT hash, name FROM torrents WHERE (tp_state IS NULL AND id = 2)'
        [
          [ 'abc', 'TestTorrent1' ]
        ]
      elsif q.include? 'SELECT id,ratio,name from torrents'
        [
          [ 2, 1500, 'TestTorrent1' ]
        ]
      elsif q.include? 'SELECT id,tp_state,name from torrents'
        [
          [ 2, 'removing', 'TestTorrent1' ]
        ]
      elsif q.include? "SELECT name from sqlite_master WHERE type = 'table' ORDER BY name"
        [
          [ 'torrents' ]
        ]
      else
        []
      end
    end

    allow(obj).to receive(:delete_torrent) do |arg|
    end

    allow(obj).to receive(:read_cache) { 'cache' }
    allow(obj).to receive(:update_cache)
    allow(obj).to receive(:update_torrents)
    allow(obj).to receive(:upgrade)

    obj
  end
end
