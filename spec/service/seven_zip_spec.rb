##############################################################################
# File::    seven_zip_spec.rb
# Purpose:: SevenZip specifications
# 
# Author::    Jeff McAffee 01/05/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require_relative '../spec_helper'

include FileUtils
include TorrentProcessor::Service

describe SevenZip do

  context ".app_path" do

    it "returns absolute path to 7z.exe" do
      SevenZip.app_path
    end
  end

  context ".app_path=" do

    it "overrides application path to executable" do
      SevenZip.app_path = 'test'
      expect(SevenZip.app_path).to eq 'test'
      # Reset to nil so we don't break other tests.
      SevenZip.app_path = nil
    end
  end

  context ".default_commands" do

    it "defaults to extract command" do
      expect(SevenZip.default_commands).to eq 'x'
    end
  end

  context ".default_switches" do

    it "defaults to 'Yes for all' switch" do
      expect(SevenZip.default_switches).to include '-y'
    end
  end

  context ".extract_rar" do

    let(:data_dir)      { 'spec/data' }
    let(:multi_rar)     { 'multi_rar' }
    let(:old_style_rar) { 'old_style_rar' }
    let(:tmp_dir) do
      mkdir_p 'tmp/spec/seven_zip'
      'tmp/spec/seven_zip'
    end

    context "current rar naming convention (*.part01.rar, *.part02.rar)" do

      context "given a directory path" do
        let(:test_dir) do
          td = File.join(tmp_dir, multi_rar)
          blocking_dir_delete td
          cp_r(File.join(data_dir, multi_rar), tmp_dir)
          td
        end
        let(:extracted_rar) { File.join(test_dir, 'test_250kb.avi') }

        it "finds and extracts a rar archive" do
          SevenZip.extract_rar(test_dir, test_dir, nil)
          expect(File.exists?(extracted_rar)).to eq true
        end
      end
    end

    context "old style rar naming convention (*.r00, *.r01, *.rar)" do

      context "given a directory path" do
        let(:test_dir) do
          td = File.join(tmp_dir, old_style_rar)
          blocking_dir_delete td
          cp_r(File.join(data_dir, old_style_rar), tmp_dir)
          td
        end
        let(:extracted_rar) { File.join(test_dir, 'test_250kb.avi') }

        it "finds and extracts a rar archive" do
          #SevenZip.extract_rar(test_dir, test_dir, SimpleLogger)
          SevenZip.extract_rar(test_dir, test_dir, nil)
          expect(File.exists?(extracted_rar)).to eq true
        end
      end
    end
  end
end

