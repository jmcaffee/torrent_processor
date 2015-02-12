module Mocks
  def self.cfg(relative_tmp_dir = '')
    tmp_dir = spec_tmp_dir(relative_tmp_dir)

    cfg = TorrentProcessor.configuration

    cfg.app_path          = tmp_dir
    cfg.logging           = false
    cfg.max_log_size      = 0
    cfg.log_dir           = tmp_dir
    cfg.tv_processing     = File.join(tmp_dir, 'media/tv')
    cfg.movie_processing  = File.join(tmp_dir, 'media/movies')
    cfg.other_processing  = File.join(tmp_dir, 'media/other')
    cfg.filters           = {}

    cfg.utorrent.ip                     = '192.168.1.103'
    cfg.utorrent.port                   = '8082'
    cfg.utorrent.user                   = 'admin'
    cfg.utorrent.pass                   = 'abc'
    cfg.utorrent.dir_completed_download = File.join(tmp_dir, 'torrents/completed')
    cfg.utorrent.seed_ratio             = 0

    cfg.tmdb.api_key              = 'itsasecret'
    cfg.tmdb.language             = 'en'
    cfg.tmdb.target_movies_path   = File.join(tmp_dir, 'movies_final')
    cfg.tmdb.can_copy_start_time  = "00:00"
    cfg.tmdb.can_copy_stop_time   = "23:59"
    cfg
  end
end
