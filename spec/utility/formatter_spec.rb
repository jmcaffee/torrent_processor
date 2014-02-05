require 'spec_helper'

include TorrentProcessor::Utility

describe Formatter do

  subject(:formatter) { Formatter.set_output_mode(:pretty); Formatter }

  its(:toggle_output_mode) { should be :raw }

  context 'by default' do
    its(:output_mode) { should be :pretty }
  end

  describe '.set_output_mode' do

    context 'only accepts certain symbols' do

      it 'accepts :pretty' do
        formatter.set_output_mode :pretty

        expect(formatter.output_mode).to be :pretty
      end

      it 'accepts :raw' do
        formatter.set_output_mode :raw

        expect(formatter.output_mode).to be :raw
      end

      it 'does not accept other values' do
        formatter.set_output_mode :pretty
        formatter.set_output_mode :foo

        expect(formatter.output_mode).to be :pretty
      end
    end # only accepts :pretty and :raw
  end # .set_output_mode
end
