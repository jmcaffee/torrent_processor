##############################################################################
# File::    plugin.rb
# Purpose:: Plugin helper classes.
# 
# Author::    Jeff McAffee 02/21/2012
# Copyright:: Copyright (c) 2012, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

##########################################################################
# TorrentProcessor module
module TorrentProcessor



  ##########################################################################
  # Plugin module
  module Plugin


    ##########################################################################
    # PluginManager class
    class PluginManager
      
      @registered_plugins = {}
      @registered_cmds = {}

      def PluginManager.registered_plugins
        @registered_plugins
      end


      def PluginManager.registered_cmds
        @registered_cmds
      end


      def PluginManager.register_plugin(plugin_type, plug_klass)
        @registered_plugins[plugin_type] = [] unless (! @registered_plugins[plugin_type].nil?)

        @registered_plugins[plugin_type] << plug_klass
        PluginManager.register_cmds(plugin_type, plug_klass)
      end


      def PluginManager.register_cmds(plugin_type, plug_klass)
        @registered_cmds[plugin_type] = {} unless (! @registered_cmds[plugin_type].nil?)

        plug_klass.register_cmds.each do |cmd_name,cmd|
          @registered_cmds[plugin_type][cmd_name] = cmd
        end
      end


      def PluginManager.command(cmdname, *args)
        cmd_parts = cmdname.split
        cmdpart = cmd_parts[0]

        @registered_cmds.each do |plugin_type, cmd_names|
          cmd_names.each do |cmdsig,cmd|
            if (cmdsig == cmdpart)
              return cmd.execute( cmdname, *args )
            end
          end   # each plugin_type command
        end   # each plugin_type

        return nil
        #raise "Command not recognized: #{cmdname}"
      end


      def PluginManager.command_list(plugin_type)
        cmd_list = []
        @registered_cmds[plugin_type].each do |cmd_name, cmdObj|
          cmd_list << [cmd_name, cmdObj.desc]
        end
        cmd_list
      end


      def dump_plugins
        PluginManager.registered_plugins.each do |plug, marray|
          puts plug.to_s
          marray.each do |meth|
            puts "  #{meth.to_s}"
          end
        end
      end


    end # class PluginManager



    ##########################################################################
    # Command class
    class Command
      def initialize(klass, mthd, desc)
        @klass = klass
        @mthd = mthd
        @desc = desc
      end


      def desc
        @desc
      end


      def execute(*args)
        @klass.new.send( @mthd, args )
      end
    
    
    end # class Command
   


    ##########################################################################
    # DBPluginBase class
    class DBPluginBase
      
      
      def DBPluginBase.register_cmds
        {".test" => Command.new(DBPluginBase, :test, "Test command"),
          ".test2" => Command.new(DBPluginBase, :test2, "Another command")}
      end


      def initialize()
        
      end
    
    
      def test(args)
        puts "Test fired with args: #{args.inspect}"
      end


      def test2(args)
        puts "Test2 fired with args: #{args.inspect}"
      end
    end # class DBPluginBase
    

    ##########################################################################
    # Tester class
    class Tester

      def run_test
        PluginManager.register_plugin(:db, DBPluginBase)
        puts PluginManager.command_list(:db).inspect
        PluginManager.command(".test", self, ".test data")
        PluginManager.command(".test2", self, ".test2 data")
      end
      
    end # class Tester


  end # module Plugin
  
end # module TorrentProcessor
