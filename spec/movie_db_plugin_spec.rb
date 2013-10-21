require 'spec_helper'
include TorrentProcessor::Plugin

describe TMDBPlugin do

    let(:ctrl)  do
      ctrl = OpenStruct.new
      ctrl.moviedb = TorrentProcessor::ProcessorPlugin::MovieDB.new('***REMOVED***')
      ctrl
    end

  it "provides console commands" do
    cmds = TMDBPlugin.register_cmds
    cmds.size.should eq 2
  end

  context "when testing the connection" do
    subject(:plugin) {TMDBPlugin.new}

    it ".test_connection connects to TMDB.org" do
      expect(plugin.test_connection([nil,ctrl])).to be true
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

    subject(:plugin) {TMDBPlugin.new}

    it "searches for a movie title" do
      expect(plugin.search_movie([total_recall_file, ctrl])[0].title).to eq total_recall_title
    end

    it "searches for a movie title with year" do
      expect(plugin.search_movie([bridesmaids_file, ctrl])[0].title).to eq bridesmaids_title
    end

    it "strips spaces and re-searches for a movie title" do
      expect(plugin.search_movie([bridesmaids_file, ctrl])[0].title).to eq bridesmaids_title
    end

    it "finds titles with missing special characters" do
      expect(plugin.search_movie([cowboys_and_aliens_file, ctrl])[0].title).to eq cowboys_and_aliens_title
    end

    it "searches for a movie title with dash" do
      expect(plugin.search_movie([a_team_file, ctrl])[0].title).to eq a_team_title
    end
  end # context search command
end
