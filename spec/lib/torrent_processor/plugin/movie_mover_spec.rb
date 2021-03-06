require 'spec_helper'
include TorrentProcessor::Plugin

describe MovieMover do

  context "when movies need to be processed" do

      let(:args) do
        {
          #logger:   SimpleLogger,
          movie_db: mdb
        }
      end

      let(:mdb)           { MovieDB.new(mdb_args) }

      let(:mdb_args) do
        {
          api_key: ENV['TMDB_API_KEY'],
          language: 'en',
          #logger:   SimpleLogger,
        }
      end

      let(:root_src_dir)  { 'tmp/spec/movie_mover/movies_src' }
      let(:root_dest_dir) { 'tmp/spec/movie_mover/movies_final' }
      let(:test_movie_1_dir)  do
        generate_movie_set(root_src_dir, 'movie_1', '.avi')
      end

      let(:big_hero_file) {'Big Hero 6-Dvdrip-H264-MRFIXIT'}
      let(:big_hero_dir)  do
        generate_movie_set(root_src_dir, big_hero_file, '.mp4')
      end

      let(:bridesmaids_file)  {'Brides Maids 2011 DVDRiP XciD AC3 - BHRG'}
      let(:bridesmaids_dir)  do
        generate_movie_set(root_src_dir, bridesmaids_file, '.avi')
      end

      let(:cowboys_file)      {'Cowboys.Aliens'}
      let(:cowboys_dir)  do
        generate_movie_set(root_src_dir, cowboys_file, '.mkv')
      end

      let(:ateam_file)        {'The.A-Team'}
      let(:ateam_dir)  do
        generate_movie_set(root_src_dir, ateam_file, '.mkv')
      end

      let(:big_hero_title)            { 'Big.Hero.6.(2014)'       }
      let(:bridesmaids_title)         { 'Bridesmaids.(2011)'        }
      let(:cowboys_title)             { 'Cowboys.and.Aliens.(2011)' }
      let(:ateam_title)               { 'The.A-Team.(2010)'         }

      let(:big_hero_final_file)       { big_hero_title + '.mp4' }
      let(:bridesmaids_final_file)    { bridesmaids_title  + '.avi' }
      let(:cowboys_final_file)        { cowboys_title      + '.mkv' }
      let(:ateam_final_file)          { ateam_title        + '.mkv' }

      let(:big_hero_final_file_path)      { File.join(root_dest_dir, big_hero_title,     big_hero_final_file) }
      let(:bridesmaids_final_file_path)   { File.join(root_dest_dir, bridesmaids_title,  bridesmaids_final_file ) }
      let(:cowboys_final_file_path)       { File.join(root_dest_dir, cowboys_title,      cowboys_final_file )     }
      let(:ateam_final_file_path)         { File.join(root_dest_dir, ateam_title,        ateam_final_file )       }

      subject(:mover)   { MovieMover.new(args) }

      before(:each) do
        blocking_dir_delete root_src_dir

        # Create the test files.
        big_hero_dir
        bridesmaids_dir
        cowboys_dir
        ateam_dir

        # Delete the final files.
        FileUtils.remove_dir(root_dest_dir) if File.exists?(root_dest_dir)
      end


    it "#get_video_file returns largest file in directory" do
      expect(mover.get_video_file(big_hero_dir).    end_with?(big_hero_file     + '.mp4')).to eq true
      expect(mover.get_video_file(bridesmaids_dir). end_with?(bridesmaids_file  + '.avi')).to eq true
      expect(mover.get_video_file(cowboys_dir).     end_with?(cowboys_file      + '.mkv')).to eq true
      expect(mover.get_video_file(ateam_dir).       end_with?(ateam_file        + '.mkv')).to eq true
    end

    it "#process processes all directories in the root movie directory" do
      mover.process(root_src_dir, root_dest_dir, -1, -1)

      expect(File.exist?(big_hero_final_file_path)).to eq true
      expect(File.exist?(big_hero_dir)).to eq false

      expect(File.exist?(bridesmaids_final_file_path)).to eq true
      expect(File.exist?(bridesmaids_dir)).to eq false

      expect(File.exist?(cowboys_final_file_path)).to eq true
      expect(File.exist?(cowboys_dir)).to eq false

      expect(File.exist?(ateam_final_file_path)).to eq true
      expect(File.exist?(ateam_dir)).to eq false
    end


    context "when logger is not provided" do
      let(:args) do
        {
          movie_db: mdb
        }
      end
      subject(:mover)   { MovieMover.new(args) }

      it "MovieMover does not blow up" do
        expect(mover.process(root_src_dir, root_dest_dir, -1, -1))
      end
    end # context "when logger is nil"
  end # context 'when movies need to be processed'
end
