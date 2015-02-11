##############################################################################
# File::    plugin_manager_base_spec.rb
# Purpose:: ProcessorPluginManager specification
# 
# Author::    Jeff McAffee 01/06/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'spec_helper'

include TorrentProcessor::Plugin

class TestPlugin
  def execute(context, args)
    #puts "#execute called with context (#{context.inspect}) and args (#{args.inspect})"
  end
end

class PPMTestClass1 < TestPlugin
end

class PPMTestClass2 < TestPlugin
end


describe ProcessorPluginManager do

  context '.execute_each' do

    it "calls #execute on each registered plugin" do
      ProcessorPluginManager.remove_all
      ProcessorPluginManager.register [PPMTestClass1, PPMTestClass2]
      ProcessorPluginManager.execute_each(Object.new, { test: 'test' })
    end
  end

  context '.register' do

    context 'given a class name' do

      it "adds a plugin class to the registration list" do
        ProcessorPluginManager.remove_all
        ProcessorPluginManager.register PPMTestClass1
        expect(ProcessorPluginManager.registered_plugins.size).to eq 1
      end
    end

    context 'given an array of class names' do

      it "adds all plugin classes to the registration list" do
        ProcessorPluginManager.remove_all
        ProcessorPluginManager.register [PPMTestClass1, PPMTestClass2]
        expect(ProcessorPluginManager.registered_plugins.size).to eq 2
      end
    end
  end

  context '.remove_all' do

    it "removes all registered plugins" do
      ProcessorPluginManager.register [PPMTestClass1, PPMTestClass2]
      ProcessorPluginManager.remove_all
      expect(ProcessorPluginManager.registered_plugins.size).to eq 0
    end
  end

  context '.registered_plugins' do

    it "returns an ordered list of registered plugin classes" do
      ProcessorPluginManager.remove_all
      ProcessorPluginManager.register [PPMTestClass1, PPMTestClass2]
      expect(ProcessorPluginManager.registered_plugins[0]).to be PPMTestClass1
      expect(ProcessorPluginManager.registered_plugins[1]).to be PPMTestClass2
    end
  end
end
