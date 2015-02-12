require 'spec_helper'

include TorrentProcessor

describe Console do

  subject(:console) { Console.new(init_args) }

  let(:init_args) do
    {
      :processor => Mocks.processor,
    }
  end

  describe '#process_console_cmd' do

    context 'cmd: .process' do

      it 'accepts the command' do
        expect(console.process_cmd('.process')).to be_truthy
      end
    end # cmd: .process
  end # #process_console_cmd
end
