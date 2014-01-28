require 'spec_helper'

describe TorrentProcessor::Utility::DirHelper do

  describe '#new' do

    it 'instantiates the helper class' do
      TorrentProcessor::Utility::DirHelper.new
    end
  end

  describe '#destination' do

    context "given a torrent's current directory and name" do

      let(:torrent_name)  { 'torrent_name' }
      let(:current_dir)   { 'current_dir' }
      let(:download_dir)  { 'current_dir' }
      let(:tv_dir)        { 'tv_dir' }
      let(:movie_dir)     { 'movie_dir' }
      let(:other_dir)     { 'other_dir' }

      before(:each) do
        TorrentProcessor.configure do |config|
          config.tv_processing    = tv_dir
          config.movie_processing = movie_dir
          config.other_processing = other_dir

          config.utorrent.dir_completed_download = download_dir
        end
      end

      context 'torrent label is TV' do

        let(:label) { 'TV' }

        it 'returns the correct destination directory' do
          expect(subject.destination(current_dir, torrent_name, label)).to eq File.join(tv_dir, torrent_name)
        end
      end # context label = TV

      context 'torrent label is Movie' do

        let(:label) { 'Movie' }

        it 'returns the correct destination directory' do
          expect(subject.destination(current_dir, torrent_name, label)).to eq File.join(movie_dir, torrent_name)
        end

        context 'torrent is in subdirectory' do

          let(:current_dir) { File.join(download_dir, 'sub_dir') }

          it 'returns a subdirectory of the destination directory' do
            expect(subject.destination(current_dir, torrent_name, label)).to eq File.join(movie_dir, 'sub_dir', torrent_name)
          end

          context 'torrent name IS the subdirectory name' do

            let(:current_dir) { File.join(download_dir, torrent_name) }
            let(:torrent_name) { 'sub_dir' }

            it 'does not append the torrent name to the subdirectory' do
              expect(subject.destination(current_dir, torrent_name, label)).to eq File.join(movie_dir, 'sub_dir')
            end
          end # context torrent name is subdirectory name
        end # context torrent in subdirectory
      end # context label = movie

      context 'torrent label is not TV or Movie' do

        let(:label) { 'Foo' }

        it 'returns the correct destination directory' do
          expect(subject.destination(current_dir, torrent_name, label)).to eq File.join(other_dir, torrent_name)
        end
      end # context label = movie
    end # context current directory, name and label
  end
end
