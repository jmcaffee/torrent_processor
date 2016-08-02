module DatabaseHelper

  def self.with_mem_db(cfg_args = {})
    cfg_args = default_init_args.merge cfg_args
    raise 'no block provided' unless block_given?

    db = Database.new(cfg_args)
    # Turn off verbose mode while setting up.
    #old = db.verbose
    #db.verbose = false

    db.filepath = ':memory:'

    db.connect
    #db.drop_all
    # Reset verbose mode.
    #db.verbose = old

    yield db

    #db.verbose = false
    db.close
  end

  def self.default_init_args
    {
      :cfg => default_cfg,
      :verbose => false, # Default: false
      :logger => ::ScreenLogger,
    }
  end

  def self.default_cfg
    cfg = TorrentProcessor.configuration

    tmp_path = spec_tmp_dir('database')

    cfg.app_path          = tmp_path
    cfg.logging           = false
    cfg.max_log_size      = 0
    cfg.log_dir           = tmp_path
    cfg.tv_processing     = File.join(tmp_path, 'media/tv')
    cfg.movie_processing  = File.join(tmp_path, 'media/movies')
    cfg.other_processing  = File.join(tmp_path, 'media/other')
    cfg.filters           = {}

    #cfg.utorrent.ip                     = '192.168.1.103'
    cfg.utorrent.ip                     = '127.0.0.1'
    cfg.utorrent.port                   = '8082'
    cfg.utorrent.user                   = 'admin'
    cfg.utorrent.pass                   = 'abc'
    cfg.utorrent.dir_completed_download = File.join(tmp_path, 'torrents/completed')
    cfg.utorrent.seed_ratio             = 0

    cfg.tmdb.api_key              = 'NOTAREALKEY'
    cfg.tmdb.language             = 'en'
    cfg.tmdb.target_movies_path   = File.join(tmp_path, 'movies_final')
    cfg.tmdb.can_copy_start_time  = "00:00"
    cfg.tmdb.can_copy_stop_time   = "23:59"
    cfg
  end
end

