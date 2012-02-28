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
      
      # Hash of all registered plugins
      @registered_plugins = {}

      # Hash of all registered commands
      @registered_cmds = {}

      ###
      # Return a hash of registered plugins
      #
      def PluginManager.registered_plugins
        @registered_plugins
      end


      ###
      # Return a hash of registered commands
      #
      def PluginManager.registered_cmds
        @registered_cmds
      end


      ###
      # Register a plugin. After the plugin has been added to the 
      # @registered_plugins hash, the plugin's register_cmds class method is
      # called to register the plugin's commands.
      #
      # *Args*
      #
      # +plugin_type+ -- a symbol that can be used to retrieve a categorized list of plugins
      #
      # +plug_klass+ -- the class constant (ie. Test) to be registered. This constant is used to instanciate the plugin on demand.
      #
      def PluginManager.register_plugin(plugin_type, plug_klass)
        @registered_plugins[plugin_type] = [] unless (! @registered_plugins[plugin_type].nil?)

        @registered_plugins[plugin_type] << plug_klass
        PluginManager.register_cmds(plugin_type, plug_klass)
      end


      ###
      # Register a plugin's commands. After the plugin has been added to the 
      # @registered_plugins hash, the plugin's register_cmds class method is
      # called to register the plugin's commands.
      #
      # *Args*
      #
      # +plugin_type+ -- a symbol that can be used to retrieve a categorized list of plugin commands
      #
      # +plug_klass+ -- the class constant (ie. Test) to be registered. This constant is used to instanciate the plugin on demand.
      #
      def PluginManager.register_cmds(plugin_type, plug_klass)
        @registered_cmds[plugin_type] = {} unless (! @registered_cmds[plugin_type].nil?)

        plug_klass.register_cmds.each do |cmd_name,cmd|
          @registered_cmds[plugin_type][cmd_name] = cmd
        end
      end


      ###
      # Call a plugin's command, passing it a set of arguments.
      #
      # *Args*
      #
      # +cmdname+ -- the command to be called, defined by the plugin's register_cmds class method
      #
      # +args+ -- a list of arguments to be passed to the plugin command
      #
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


      ###
      # Returns an array of arrays containing the plugin command and a desciption.
      # The command and description are defined by the plugin's register_cmds class method.
      #
      # *Args*
      #
      # +plugin_type+ -- an arbitrary symbol used to classify the plugin 'type'
      #
      # *Returns*
      #
      # array of arrays [ [cmd name, cmd desc] ]
      #
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
    #
    # Object used to encapsulate a command, the method that should be called 
    # when the command is activated, and a description of the command.
    class Command

      ###
      # *Args*
      #
      # +klass+ -- class constant (ie. Test) used to instanciate the object
      #
      # +mthd+ -- method symbol to call (ie. :some_method_name)
      #
      # +desc+ -- description of the command
      #
      def initialize(klass, mthd, desc)
        @klass = klass
        @mthd = mthd
        @desc = desc
      end


      ###
      # Return the command's description
      #
      def desc
        @desc
      end


      ###
      # Execute the command passing it any args provided.
      #
      # *Args*
      #
      # +args+ -- argument list to be passed to the command
      #
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
