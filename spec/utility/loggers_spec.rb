require 'spec_helper'

describe FileLogger do

  subject(:file_logger) do
    FileLogger.logfile = nil
    FileLogger.logdir = nil
    FileLogger
  end

  let(:tmp_path) do
    pth = 'tmp/spec/loggers'
    mkpath pth
    pth
  end

  its(:logfile) { should == 'torrentprocessor.log' }

  its(:logdir) { should == '.' }

  its(:logpath) { should == './torrentprocessor.log' }

  its(:max_log_size) { should == 1024 * 500 }

  describe '.rotate_log' do

    context 'log has reached max size' do

      before(:each) do
        blocking_dir_delete(tmp_path)
      end

      after(:each) do
        subject.logfile = nil
        subject.logdir = nil
        subject.max_log_size = nil
      end

      let(:initial_log) do
        create_file_of_size log_00, 1025
      end

      let(:log_00) do
        File.join(tmp_path, 'torrentprocessor.log')
      end

      let(:log_01) do
        File.join(tmp_path, 'torrentprocessor.log.1')
      end

      it 'rotates the log to 01' do
        initial_log

        subject.max_log_size = 1024
        subject.logdir = tmp_path

        subject.rotate_log

        expect(File.exists?(log_01)).to be_true
      end
    end
  end

end
