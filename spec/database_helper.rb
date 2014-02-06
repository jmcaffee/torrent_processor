
module DatabaseHelper

  def database_stub
    obj = double('database')
    obj.stub(:connect)  { true }
    obj.stub(:close)    { true }
    obj.stub(:execute) do |q|
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

    obj.stub(:delete_torrent) do |arg|
    end

    obj.stub(:read_cache) { 'cache' }
    obj.stub(:update_cache)
    obj.stub(:update_torrents)
    obj.stub(:upgrade)

    obj
  end
end # module DatabaseHelper
