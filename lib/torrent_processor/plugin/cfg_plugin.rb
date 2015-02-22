##############################################################################
# File::    cfg_plugin.rb
# Purpose:: TorrentProcessor Configuration Plugin class.
#
# Author::    Jeff McAffee 02/22/2012
# Copyright:: Copyright (c) 2012, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'ktcommon/ktcmdline'
#require_relative '../utility/formatter'

module TorrentProcessor
  module Plugin

  class CfgPlugin < BasePlugin
    include ::KtCmdLine
    include TorrentProcessor
    include TorrentProcessor::Utility

    def CfgPlugin.register_cmds
      { ".user" =>        Command.new(CfgPlugin, :cfg_user,       "Configure Torrent app user"),
        ".pwd" =>         Command.new(CfgPlugin, :cfg_pwd,        "Configure Torrent app password"),
        ".ip" =>          Command.new(CfgPlugin, :cfg_ip,         "Configure Torrent app IP address"),
        ".port" =>        Command.new(CfgPlugin, :cfg_port,       "Configure Torrent app Port"),
        ".addfilter" =>   Command.new(CfgPlugin, :cfg_addfilter,  "Add a tracker seed filter"),
        ".delfilter" =>   Command.new(CfgPlugin, :cfg_delfilter,  "Delete a tracker seed filter"),
        ".listfilters" => Command.new(CfgPlugin, :cfg_listfilters,"List current tracker filters"),
        #"." => Command.new(CfgPlugin, :, ""),
      }
    end

    ###
    # Configure Torrent app user
    #
    def cfg_user(args)
      parse_args args
      user_name = cmd_arguments('.user', args[:cmd])

      log " Current username: #{get_user}"
      unless user_name.empty?
        set_user user_name

        log " Username changed to: #{get_user}"
      end

      return true
    end

    ###
    # Configure Torrent app password
    #
    def cfg_pwd(args)
      parse_args args
      user_pwd = cmd_arguments('.pwd', args[:cmd])

      log " Current password: #{get_pwd}"
      unless user_pwd.empty?
        set_pwd user_pwd

        log " Password changed to: #{get_pwd}"
      end

      return true
    end

    ###
    # Configure Torrent app IP address
    #
    def cfg_ip(args)
      parse_args args
      ip = cmd_arguments('.ip', args[:cmd])

      log " Current address: #{get_ip}:#{get_port}"
      unless ip.empty?
        set_ip ip

        log " Address changed to: #{get_ip}:#{get_port}"
      end

      return true
    end

    ###
    # Configure Torrent app Port
    #
    def cfg_port(args)
      parse_args args
      port = cmd_arguments('.port', args[:cmd])

      log " Current address: #{get_ip}:#{get_port}"
      unless port.empty?
        set_port port

        log " Address changed to: #{get_ip}:#{get_port}"
      end

      return true
    end

    ###
    # Add a tracker seed filter
    #
    def cfg_addfilter(args)
      parse_args args

      new_filter = cmd_arguments('.addfilter', args[:cmd])
      new_filter = new_filter.split

      if new_filter.size == 2
        cfg.filters[new_filter[0]] = new_filter[1]
        save_cfg

        log " Filter added. Tracker: #{new_filter[0]}, Max ratio: #{new_filter[1]}"
      else
        log 'Usage: .addfilter some.tracker.url ratio'
      end

      return true
    end

    ###
    # Delete a tracker seed filter
    #
    def cfg_delfilter(args)
      parse_args args

      del_filter = cmd_arguments('.delfilter', args[:cmd])
      if del_filter.empty?
        log 'Usage: .delfilter some.tracker.url'
        log '       use .listfilters to see a list of current filters'
        return true
      end

      if cfg.filters[del_filter].nil?
        log " Unknown filter: #{del_filter}"
        return true
      end

      cfg.filters.delete del_filter
      save_cfg

      log " Filter deleted (#{del_filter})"

      return true
    end

    ###
    # List all tracker seed filters
    #
    def cfg_listfilters(args)
      parse_args args

      log "Current Filters:"
      Formatter.print_rule
      filters = cfg.filters
      if (filters.nil? || filters.length < 1)
        log " None"
        return true
      end

      filters.each do |tracker, seedlimit|
        log " #{tracker} : #{seedlimit}"
      end

      return true
    end

  protected

    def defaults
      {
        :logger => NullLogger
      }
    end

  private

    ###
    # Strips a command off of a string.
    def cmd_arguments cmd, cmd_string
      args = cmd_string.gsub(cmd, '').strip
    end

    def cfg
      TorrentProcessor.configuration
    end

    def save_cfg
      TorrentProcessor.save_configuration
    end

    def backend_cfg
      if cfg.backend == :utorrent
        return cfg.utorrent
      else
        return cfg.qbtorrent
      end
    end

    def get_ip
      backend_cfg.ip
    end

    def get_port
      backend_cfg.port
    end

    def get_user
      backend_cfg.user
    end

    def get_pwd
      backend_cfg.pass
    end

    def set_ip ip
      backend_cfg.ip = ip
      save_cfg
    end

    def set_port port
      backend_cfg.port = port
      save_cfg
    end

    def set_user user
      backend_cfg.user = user
      save_cfg
    end

    def set_pwd pwd
      backend_cfg.pass = pwd
      save_cfg
    end
  end # class CfgPlugin
  end # module
end # module TorrentProcessor::Plugin
