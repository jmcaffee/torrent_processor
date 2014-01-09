require 'spec_helper'
include TorrentProcessor::Plugin

describe MovieDB do

  context "with a valid API key" do
      subject(:mdb) {MovieDB.new('***REMOVED***')}

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

      let(:ctrl) do
        obj = double('controller')
        obj.stub(:moviedb) { mdb }
        obj
      end

      it "provides console commands" do
        cmds = MovieDB.register_cmds
        cmds.size.should eq 2
      end

      context "when testing the connection" do

        it ".test_connection connects to TMDB.org" do
          expect(mdb.cmd_test_connection([nil,ctrl])).to be true
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
          expect(mdb.cmd_search_movie([total_recall_file, ctrl])[0].title).to eq total_recall_title
        end

        it "searches for a movie title with year" do
          expect(mdb.cmd_search_movie([bridesmaids_file, ctrl])[0].title).to eq bridesmaids_title
        end

        it "strips spaces and re-searches for a movie title" do
          expect(mdb.cmd_search_movie([bridesmaids_file, ctrl])[0].title).to eq bridesmaids_title
        end

        it "finds titles with missing special characters" do
          expect(mdb.cmd_search_movie([cowboys_and_aliens_file, ctrl])[0].title).to eq cowboys_and_aliens_title
        end

        it "searches for a movie title with dash" do
          expect(mdb.cmd_search_movie([a_team_file, ctrl])[0].title).to eq a_team_title
        end
      end # context search command
    end # context "console commands"
  end # valid API key context
end
