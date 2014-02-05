require 'spec_helper'

include TorrentProcessor::Utility

describe Formatter do

  subject(:formatter) do
    Formatter.set_output_mode(:pretty)
    Formatter.logger = nil
    Formatter
  end

  its(:toggle_output_mode) { should be :raw }

  context 'by default' do
    its(:output_mode) { should be :pretty }

    its(:logger) { should be NullLogger }
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

  describe '.logger=' do

    it 'sets a logger class' do
      formatter.logger = CaptureLogger

      expect(formatter.logger).to be CaptureLogger
    end
  end # .logger=

  context 'has formatting helper methods' do

    before(:each) do
      formatter.logger = CaptureLogger
      CaptureLogger.reset
    end

    describe '.print_rule' do

      it 'prints a row of dashes' do
        formatter.print_rule
        expect(CaptureLogger.messages.include?('-'*40)).to be_true
      end
    end # .print_rule

    describe '.print_header' do

      it 'prints a header message' do
        msg = 'Foo Bar'
        formatter.print_header msg

        expect(CaptureLogger.messages.include?(msg)).to be_true
      end

      it 'prints row of "=" matching length of message' do
        msg = 'Foo Bar'
        hdr = '=' * msg.size
        formatter.print_header msg

        expect(CaptureLogger.messages.include?(hdr)).to be_true
      end
    end # .print_header

    describe '.print_query_results' do

      context ':raw mode' do

        before(:each) { Formatter.set_output_mode(:raw) }

        it 'prints values without modification' do
          msg = 'Foo Bar'
          formatter.print_query_results msg
          expect(CaptureLogger.messages.include?(msg)).to be_true

          msg = ['Foo', 'Bar', 'Baz']
          formatter.print_query_results msg
          expect(CaptureLogger.messages.include?(msg)).to be_true
        end
      end # :raw mode

      it 'prints row of "=" matching length of message' do
        msg = 'Foo Bar'
        hdr = '=' * msg.size
        formatter.print_header msg

        expect(CaptureLogger.messages.include?(hdr)).to be_true
      end
    end # .print_query_results
  end # has formatting helper methods
end
