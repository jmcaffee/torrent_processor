##############################################################################
# File::    cmd_plugin_manager.rb
# Purpose:: Manage all registered plugins
#
# Author::    Jeff McAffee 02/21/2012
# Copyright:: Copyright (c) 2012, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

module TorrentProcessor::Plugin

  class CmdPluginManager

    # Hash of all registered plugins
    @registered_plugins = {}

    # Hash of all registered commands
    @registered_cmds = {}

    ###
    # Return a hash of registered plugins
    #
    def CmdPluginManager.registered_plugins
      @registered_plugins
    end


    ###
    # Return a hash of registered commands
    #
    def CmdPluginManager.registered_cmds
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
    def CmdPluginManager.register_plugin(plugin_type, plug_klass)
      @registered_plugins[plugin_type] = [] unless (! @registered_plugins[plugin_type].nil?)

      @registered_plugins[plugin_type] << plug_klass
      CmdPluginManager.register_cmds(plugin_type, plug_klass)
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
    def CmdPluginManager.register_cmds(plugin_type, plug_klass)
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
    def CmdPluginManager.command(cmdname, args)
      cmd_parts = cmdname.split
      cmdpart = cmd_parts[0]

      @registered_cmds.each do |plugin_type, cmd_names|
        cmd_names.each do |cmdsig,cmd|
          if (cmdsig == cmdpart)
            args[:cmd] = cmdname
            return cmd.execute( args )
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
    def CmdPluginManager.command_list(plugin_type)
      cmd_list = []
      @registered_cmds[plugin_type].each do |cmd_name, cmdObj|
        cmd_list << [cmd_name, cmdObj.desc]
      end
      cmd_list
    end


    def dump_plugins
      CmdPluginManager.registered_plugins.each do |plug, marray|
        puts plug.to_s
        marray.each do |meth|
          puts "  #{meth.to_s}"
        end
      end
    end
  end # class CmdPluginManager
end # module TorrentProcessor::Plugin
