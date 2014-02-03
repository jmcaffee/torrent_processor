##############################################################################
# File::    test_processor.rb
# Purpose:: Test Processor class functionality
# 
# Author::    Jeff McAffee 07/31/2011
# Copyright:: Copyright (c) 2011, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'test/unit'
require 'flexmock/test_unit'
#require 'testhelper/filecomparer'
require 'logger'

require 'fileutils'

require 'lib/torrentprocessor'


###
# Test the Processor class
#
class  TestProcessor < Test::Unit::TestCase
	include FileUtils
	include FlexMock::TestCase
	include TorrentProcessor

	
	###
	# Set up test fixture
	#
  def setup
    $LOG = Logger.new(STDERR)
    $LOG.level = Logger::DEBUG
    @baseDir = File.dirname(__FILE__)
    @dataDir = File.join(@baseDir, "data")
    
		@model = Processor.new(nil)
  end

  
	###
	# Clean up test fixture
	#
  def teardown
		@model = nil
  end

  
	###
	# Delete a file if it exists
	#
	def deletefile(filepath)
		if(File.exists?(filepath))
			FileUtils.rm(filepath)
			return true
		end
	
		return false	# No file to delete
	end
	
	
	###
	# Test the constructor
	#
  def test_processor_ctor
    target = Processor.new(nil)
    assert(nil != target)
  end

  
	###
	# Test Processor does something
	#
  def test_processor_does_something
    
  end
  

	###
	# Test testtrue returns true
	#
  def test_processor_testtrue
    assert(true == @model.testTrue(), "TestTrue failed." )
  end
  

	###
	# Test testfalse returns false
	#
  def test_processor_testfalse
    assert(false == @model.testFalse(), "TestFalse failed." )
  end
  

end # TestProcessor
