##############################################################################
# File::    cfgplugin.rb
# Purpose:: TorrentProcessor Configuration Plugin class.
# 
# Author::    Jeff McAffee 02/22/2012
# Copyright:: Copyright (c) 2012, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'ktcommon/ktcmdline'

##########################################################################
# TorrentProcessor module
module TorrentProcessor



  ##########################################################################
  # Plugin module
  module Plugin



    ##########################################################################
    # CfgPlugin class
    class CfgPlugin
      include ::KtCmdLine
      
      def CfgPlugin.register_cmds
        { ".setup" =>       Command.new(CfgPlugin, :cfg_setup,      "Run TorrentProcessor setup"),
          ".user" =>        Command.new(CfgPlugin, :cfg_user,       "Configure uTorrent user"),
          ".pwd" =>         Command.new(CfgPlugin, :cfg_pwd,        "Configure uTorrent password"),
          ".ip" =>          Command.new(CfgPlugin, :cfg_ip,         "Configure uTorrent IP address"),
          ".port" =>        Command.new(CfgPlugin, :cfg_port,       "Configure uTorrent Port"),
          ".addfilter" =>   Command.new(CfgPlugin, :cfg_addfilter,  "Add a tracker seed filter"),
          ".delfilter" =>   Command.new(CfgPlugin, :cfg_delfilter,  "Delete a tracker seed filter"),
          ".listfilters" => Command.new(CfgPlugin, :cfg_listfilters,"List current tracker filters"),
          #"." => Command.new(CfgPlugin, :, ""),
        }
      end


      ###
      # Run TorrentProcessor setup
      #
      def cfg_setup(args)
        $LOG.debug "CfgPlugin::cfg_setup"
        cmdtxt = args[0]
        kaller = args[1]
        ctrl = kaller.controller
        
        ctrl.setupApp()

        return true
      end


      ###
      # Configure uTorrent user
      #
      def cfg_user(args)
        $LOG.debug "CfgPlugin::cfg_user"
        cmdtxt = args[0]
        kaller = args[1]
        ctrl = kaller.controller
        
        puts " Current username: #{ctrl.cfg[:user]}"
        newuser = getInput( " New username: " )
        ctrl.set_user(newuser)

        puts " Username changed to: #{ctrl.cfg[:user]}"
        return true
      end


      ###
      # Configure uTorrent password
      #
      def cfg_pwd(args)
        $LOG.debug "CfgPlugin::cfg_pwd"
        cmdtxt = args[0]
        kaller = args[1]
        ctrl = kaller.controller

        puts " Current password: #{ctrl.cfg[:pass]}"
        newpass = getInput( " New password: " )
        ctrl.set_pwd(newpass)

        puts " Password changed to: #{ctrl.cfg[:pass]}"
        return true
      end


      ###
      # Configure uTorrent IP address
      #
      def cfg_ip(args)
        $LOG.debug "CfgPlugin::cfg_ip"
        cmdtxt = args[0]
        kaller = args[1]
        ctrl = kaller.controller

        puts " Current address: #{ctrl.cfg[:ip]}:#{ctrl.cfg[:port]}"
        newip = getInput( " New IP address: " )
        ctrl.set_ip(newip)

        puts " Address changed to: #{ctrl.cfg[:ip]}:#{ctrl.cfg[:port]}"
        return true
      end


      ###
      # Configure uTorrent Port
      #
      def cfg_port(args)
        $LOG.debug "CfgPlugin::cfg_port"
        cmdtxt = args[0]
        kaller = args[1]
        ctrl = kaller.controller

        puts " Current address: #{ctrl.cfg[:ip]}:#{ctrl.cfg[:port]}"
        newport = getInput( " New port #: " )
        ctrl.set_port(newport)

        puts " Address changed to: #{ctrl.cfg[:ip]}:#{ctrl.cfg[:port]}"
        return true
      end


      ###
      # Add a tracker seed filter
      #
      def cfg_addfilter(args)
        $LOG.debug "CfgPlugin::cfg_addfilter"
        cmdtxt = args[0]
        kaller = args[1]
        ctrl = kaller.controller
        
        tracker = getInput( " trackers contains:" )
        seedval = getInput( " set seed limit to: " )
        
        if tracker.empty? || seedval.empty?
          puts "Add filter cancelled (invalid input)."
          return true
        end

        ctrl.add_filter( tracker, seedval )
        puts "Filter added for #{tracker} with a seed limit of #{seedval}"
        puts 
        return true
      end


      ###
      # Delete a tracker seed filter
      #
      def cfg_delfilter(args)
        $LOG.debug "CfgPlugin::cfg_delfilter"
        cmdtxt = args[0]
        kaller = args[1]
        ctrl = kaller.controller
        
        cfg_listfilters([nil,kaller])
        puts
        tracker = getInput( " tracker:" )
        
        if tracker.empty?
          puts "Delete filter cancelled (invalid input)."
          return true
        end

        ctrl.delete_filter( tracker )
        puts "Filter removed for #{tracker}"
        puts
        return true
      end


      ###
      # List all tracker seed filters
      #
      def cfg_listfilters(args)
        $LOG.debug "CfgPlugin::cfg_listfilters"
        cmdtxt = args[0]
        kaller = args[1]
        ctrl = kaller.controller
        
        puts "Current Filters:"
        Formatter.pHr
        filters = ctrl.cfg[:filters]
        puts " None" if (filters.nil? || filters.length < 1)
        return true if (filters.nil? || filters.length < 1)
        
        filters.each do |tracker, seedlimit|
          puts " #{tracker} : #{seedlimit}"
        end
        puts
        return true
      end


    end # class CfgPlugin
    


  end # module Plugin
  
end # module TorrentProcessor
