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
      { ".user" =>        Command.new(CfgPlugin, :cfg_user,       "Configure uTorrent user"),
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
    # Configure uTorrent user
    #
    def cfg_user(args)
      parse_args args
      user_name = cmd_arguments('.user', args[:cmd])

      log " Current username: #{cfg.utorrent.user}"
      unless user_name.empty?
        cfg.utorrent.user = user_name
        save_cfg

        log " Username changed to: #{cfg.utorrent.user}"
      end

      return true
    end

    ###
    # Configure uTorrent password
    #
    def cfg_pwd(args)
      parse_args args
      user_pwd = cmd_arguments('.pwd', args[:cmd])

      log " Current password: #{cfg.utorrent.pass}"
      unless user_pwd.empty?
        cfg.utorrent.pass = user_pwd
        save_cfg

        log " Password changed to: #{cfg.utorrent.pass}"
      end

      return true
    end

    ###
    # Configure uTorrent IP address
    #
    def cfg_ip(args)
      parse_args args
      ip = cmd_arguments('.ip', args[:cmd])

      log " Current address: #{cfg.utorrent.ip}:#{cfg.utorrent.port}"
      unless ip.empty?
        cfg.utorrent.ip = ip
        save_cfg

        log " Address changed to: #{cfg.utorrent.ip}:#{cfg.utorrent.port}"
      end

      return true
    end

    ###
    # Configure uTorrent Port
    #
    def cfg_port(args)
      parse_args args
      port = cmd_arguments('.port', args[:cmd])

      log " Current address: #{cfg.utorrent.ip}:#{cfg.utorrent.port}"
      unless port.empty?
        cfg.utorrent.port = port
        save_cfg

        log " Address changed to: #{cfg.utorrent.ip}:#{cfg.utorrent.port}"
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
  end # class CfgPlugin
  end # module
end # module TorrentProcessor::Plugin
