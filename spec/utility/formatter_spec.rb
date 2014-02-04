require 'spec_helper'

include TorrentProcessor::Utility

describe Formatter do

  subject(:formatter) { Formatter.setOutputMode(:pretty); Formatter }

  its(:output_mode) { should be :pretty }

  its(:toggle_output_mode) { should be :raw }
end
