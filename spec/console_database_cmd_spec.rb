require 'spec_helper'
require 'database_helper'

include TorrentProcessor

describe Database do

  include DatabaseHelper

  subject(:console) { Console.new(init_args) }

  let(:init_args) do
    {
      :logger => CaptureLogger,
      :utorrent => utorrent_stub,
      :database => database_stub,
    }
  end

  let(:utorrent_stub) { double('utorrent') }

  describe '#process_cmd' do

    before(:each) { CaptureLogger.reset }

    context 'cmd: .tables' do

      it 'displays tables used in database' do
        expect(console.process_cmd('.tables')).to be_true
        expect(CaptureLogger.contains('Connected successfully')).to be_true
      end
    end # cmd: .testcon
  end # #process_cmd
end
