require 'spec_helper'
include TorrentProcessor::Plugin

describe MovieDB do

  context "with a valid API key" do
      subject(:mdb) {MovieDB.new(args)}

      let(:args) do
        {
          api_key: ENV['TMDB_API_KEY'],
          #logger: SimpleLogger,
        }
      end

    context "when testing the connection" do

      it ".test_connection connects to TMDB.org" do
        expect(mdb.test_connection()).to be true
      end
    end


    context "when searching for a movie" do
        let(:total_recall_file)         {'Total Recall-Dvdrip-H264-MRFIXIT'}
        let(:total_recall_title)        {'Total Recall'}
        let(:bridesmaids_file)          {'Brides Maids 2011 DVDRiP XciD AC3 - BHRG.avi'}
        let(:bridesmaids_title)         {'Bridesmaids'}
        let(:cowboys_and_aliens_file)   {'Cowboys.Aliens.mkv'}
        let(:cowboys_and_aliens_title)  {'Cowboys & Aliens'}
        let(:a_team_file)               {'The.A-Team.mkv'}
        let(:a_team_title)              {'The A-Team'}

      it "searches for a movie title" do
        expect(mdb.search_movie(total_recall_file)[0].title).to eq total_recall_title
      end

      it "searches for a movie title with year" do
        expect(mdb.search_movie(bridesmaids_file)[0].title).to eq bridesmaids_title
      end

      it "strips spaces and re-searches for a movie title" do
        expect(mdb.search_movie(bridesmaids_file)[0].title).to eq bridesmaids_title
      end

      it "finds titles with missing special characters" do
        expect(mdb.search_movie(cowboys_and_aliens_file)[0].title).to eq cowboys_and_aliens_title
      end

      it "searches for a movie title with dash" do
        expect(mdb.search_movie(a_team_file)[0].title).to eq a_team_title
      end
    end # context search command

    context "console commands" do

      it "provides console commands" do
        cmds = MovieDB.register_cmds
        expect(cmds.size).to eq 2
      end

      context "when testing the connection" do

        it ".test_connection connects to TMDB.org" do
          args[:cmd] = '.tmdbtestcon'
          expect(mdb.cmd_test_connection(args)).to be true
        end
      end


      context "when searching for a movie" do
            let(:total_recall_file)         {'Total Recall-Dvdrip-H264-MRFIXIT'}
            let(:total_recall_title)        {'Total Recall'}
            let(:bridesmaids_file)          {'Brides Maids 2011 DVDRiP XciD AC3 - BHRG.avi'}
            let(:bridesmaids_title)         {'Bridesmaids'}
            let(:cowboys_and_aliens_file)   {'Cowboys.Aliens.mkv'}
            let(:cowboys_and_aliens_title)  {'Cowboys & Aliens'}
            let(:a_team_file)               {'The.A-Team.mkv'}
            let(:a_team_title)              {'The A-Team'}

        it "searches for a movie title" do
          args[:cmd] = '.tmdbmoviesearch ' + total_recall_file
          expect(mdb.cmd_search_movie(args)[0].title).to eq total_recall_title
        end

        it "searches for a movie title with year" do
          args[:cmd] = '.tmdbmoviesearch ' + bridesmaids_file
          expect(mdb.cmd_search_movie(args)[0].title).to eq bridesmaids_title
        end

        it "strips spaces and re-searches for a movie title" do
          args[:cmd] = '.tmdbmoviesearch ' + bridesmaids_file
          expect(mdb.cmd_search_movie(args)[0].title).to eq bridesmaids_title
        end

        it "finds titles with missing special characters" do
          args[:cmd] = '.tmdbmoviesearch ' + cowboys_and_aliens_file
          expect(mdb.cmd_search_movie(args)[0].title).to eq cowboys_and_aliens_title
        end

        it "searches for a movie title with dash" do
          args[:cmd] = '.tmdbmoviesearch ' + a_team_file
          expect(mdb.cmd_search_movie(args)[0].title).to eq a_team_title
        end
      end # context search command
    end # context "console commands"
  end # valid API key context
end
