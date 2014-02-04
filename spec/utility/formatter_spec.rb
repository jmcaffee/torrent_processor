require 'spec_helper'

include TorrentProcessor::Utility

describe Formatter do

  subject(:formatter) { Formatter }

  its(:output_mode) { should be :pretty }
end
