##############################################################################
# File::    plugin_manager_base_spec.rb
# Purpose:: PluginManagerBase specification
# 
# Author::    Jeff McAffee 01/06/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'spec_helper'

include TorrentProcessor

class TestClass1; end;
class TestClass2; end;

describe PluginManagerBase do

  context '.register' do

    context 'given a class name' do

      it "adds a plugin class to the registration list" do
        ProcessorPluginManager.remove_all
        PluginManagerBase.register TestClass1
        expect(PluginManagerBase.registered_plugins.size).to eq 1
      end
    end

    context 'given an array of class names' do

      it "adds all plugin classes to the registration list" do
        PluginManagerBase.remove_all
        PluginManagerBase.register [TestClass1, TestClass2]
        expect(PluginManagerBase.registered_plugins.size).to eq 2
      end
    end
  end

  context '.remove_all' do

    it "removes all registered plugins" do
      PluginManagerBase.register [TestClass1, TestClass2]
      PluginManagerBase.remove_all
      expect(PluginManagerBase.registered_plugins.size).to eq 0
    end
  end

  context '.registered_plugins' do

    it "returns an ordered list of registered plugin classes" do
      PluginManagerBase.remove_all
      PluginManagerBase.register [TestClass1, TestClass2]
      expect(PluginManagerBase.registered_plugins[0]).to be TestClass1
      expect(PluginManagerBase.registered_plugins[1]).to be TestClass2
    end
  end
end
