require 'spec_helper'
include TorrentProcessor

describe TPSetup do

  context "when setting up the application configuration" do
      let(:cfg)           do
                            cfg = {}
                            tmp_path = File.absolute_path(File.join(File.dirname(__FILE__), '../../tmp/spec/tpsetup'))
                            cfg[:appPath] = tmp_path
                            cfg[:version]  = TorrentProcessor::VERSION
                            cfg[:logging]  = false
                            cfg[:filters] = {}
                            cfg[:ip] = '127.0.0.1'
                            cfg[:port] = '8081'
                            cfg[:user] = 'testuser'
                            cfg[:pass] = 'testpass'
                            cfg[:tmdb_api_key] = '***REMOVED***'
                            cfg[:target_movies_path] = 'tmp/spec/tpsetup/movies_final'
                            cfg[:can_copy_start_time] = "00:00"
                            cfg[:can_copy_stop_time] = "23:59"
                            cfg
                          end
      let(:controller)    do
                            class SpecController
                              def initialize(cfg)
                                @cfg = cfg
                              end

                              def cfg
                                return @cfg
                              end
                            end

                            SpecController.new(cfg)
                          end


      subject(:setup)   { TPSetup.new(controller) }

      before(:each) do
        puts "cfg:"
        cfg.each do |k,v|
          puts "#{k}\t#{v}"
        end
      end


    it "#setup_config" do
      expect(setup.setup_config)
    end
  end # context 'when movies need to be processed'
end
