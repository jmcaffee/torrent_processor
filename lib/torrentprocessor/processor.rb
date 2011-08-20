##############################################################################
# File::    processor.rb
# Purpose:: Model object for TorrentProcessor.
# 
# Author::    Jeff McAffee 07/31/2011
# Copyright:: Copyright (c) 2011, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'ktcommon/ktpath'
require 'ktcommon/ktcmdline'
require 'utorrentwebui'


module TorrentProcessor
	  
	##########################################################################
	# Processor class
	class Processor
	
	attr_reader 		:controller
	attr_reader 		:srcdir
	attr_reader 		:srcfile
	attr_reader 		:state
	attr_reader 		:prevstate
	attr_reader 		:msg
	attr_reader 		:label
	attr_reader 		:verbose
		
		###
		# Processor constructor
		#
		def initialize(controller)
			$LOG.debug "Processor::initialize"
			
			@controller = controller
			@srcdir 		= nil
			@srcfile		= nil
			@verbose		= false
			@utorrent		= nil
			
		end
	  

		###
		# Set the srcdir
		#
		# srcdirpath:: input file path
		#
		def srcdir=(srcdirpath)
			$LOG.debug "Processor::srcdir=( #{srcdirpath} )"
			@srcdir = srcdirpath
		end
		  
	  
		###
		# Set the srcfile
		#
		# srcfilepath:: input file path
		#
		def srcfile=(srcfilepath)
			$LOG.debug "Processor::srcfile=( #{srcfilepath} )"
			@srcfile = srcfilepath
		end
		  
	  
		###
		# Set the current state
		#
		# state:: current torrent state
		#
		def state=(stateval)
			$LOG.debug "Processor::state=( #{stateval} )"
			@state = stateval
		end
		  
	  
		###
		# Set the previous state
		#
		# stateval:: previous torrent state
		#
		def prevstate=(stateval)
			$LOG.debug "Processor::prevstate=( #{stateval} )"
			@prevstate = stateval
		end
		  
	  
		###
		# Set the uTorrent msg
		#
		# msgval:: uTorrent msg
		#
		def msg=(msgval)
			$LOG.debug "Processor::msg=( #{msgval} )"
			@msg = msgval
		end
		  
	  
		###
		# Set the uTorrent label
		#
		# labelval:: uTorrent label
		#
		def label=(labelval)
			$LOG.debug "Processor::label=( #{labelval} )"
			@label = labelval
		end
		  
	  
		###
		# Set the verbose flag
		#
		# arg:: verbose mode if true
		#
		def verbose=(arg)
			$LOG.debug "Processor::verbose=( #{arg} )"
			@verbose = arg
		end
		  
	  
		###
		# Return a utorrent instance
		#
		def utorrent()
			$LOG.debug "Processor::utorrent()"
		
			return @utorrent unless @utorrent.nil?
			
			cfg = @controller.cfg
			@utorrent = UTorrentWebUI.new(cfg[:ip], cfg[:port], cfg[:user], cfg[:pass])
			
		end
		
		
		###
		# TODO: write process() description
		#
		def process()
			$LOG.debug "Processor::process"
			
			retrieve_utorrent_settings()
			
			@controller.log( "Requesting torrent list update" )
			
			# Get a list of torrents.
			cacheID = @controller.database.read_cache()
			utorrent.get_torrent_list( cacheID )
			@controller.database.update_cache( utorrent.cache )
			
			# Update the db's list of torrents.
			@controller.database.update_torrents( utorrent.torrents )
			
			# Update the db torrent list states
			update_torrent_states()
			
			# Remove any torrents from the db that have been removed from utorrent (due to a request).
			if utorrent.torrents_removed?
				remove_torrents( utorrent.removed_torrents )
			else
				# 'Cleanup' DB by removing torrents that are in the DB (awaiting removal) 
				# but are no longer in the (utorrent) torrents list due to missing a cache.
				# By missing a cache, utorrent is not sending the 'removed' torrents, only what is currently in its list.
				remove_missing_torrents( utorrent.torrents )
			end
			
			# Process torrents that are awaiting processing.
			process_torrents_awaiting_processing()
			
			# Process torrents that have completed processing.
			update_torrents_completed_processing()
				
			# Process torrents that have completed seeding.
			process_torrents_completed_seeding()
			
		end
		  
	  
		###
		# Retrieve the current uTorrent settings. seed_ratio in particular.
		#
		def retrieve_utorrent_settings()
			$LOG.debug "Processor::retrieve_utorrent_settings()"
			
			@controller.log( "--- Requesting uTorrent Settings ---" )
			settings = utorrent.get_utorrent_settings()
			settings.each do |i|
				if i[0] == "seed_ratio"
					@seed_ratio = Integer(i[2])
					@controller.log( "    uTorrent seed ratio: #{@seed_ratio.to_s}" )
					next
				end
				
				if i[0] == "dir_completed_download"
					@dir_completed_download = i[2]
					@controller.log( "    uTorrent completed download dir: #{@dir_completed_download}" )
					next
				end
			end
		
		end
		
		
		###
		# Update torrent states within the DB
		#
		def update_torrent_states()
			$LOG.debug "Processor::update_torrent_states()"
			
				# Get list of torrents where state = NULL
				q = "SELECT hash, percent_progress, name FROM torrents WHERE tp_state IS NULL;"
				rows = @controller.database.execute(q)
				
				# For each torrent where download percentage < 100, set state = downloading
				rows.each do |r|
					if r[1] < 1000
						@controller.database.update_torrent_state(r[0], "downloading")
						@controller.log( "State set to downloading: #{r[2]}" )
					else
						@controller.database.update_torrent_state(r[0], "download complete")
						@controller.log( "State set to downloading complete: #{r[2]}" )
					end
				end
				
				# Get list of torrents where state = downloading
				q = "SELECT hash, percent_progress, name FROM torrents WHERE tp_state = \"downloading\";"
				rows = @controller.database.execute(q)

				# For each torrent where download percentage = 100, set state = download complete
				rows.each do |r|
					if r[1] >= 1000
						@controller.database.update_torrent_state(r[0], "download complete")
						@controller.log( "State set to downloading complete: #{r[2]}" )
					end
				end
								
				# Get list of torrents where state = download complete
				q = "SELECT hash, name FROM torrents WHERE tp_state = \"download complete\";"
				rows = @controller.database.execute(q)

				# For each torrent where state = download complete, set state = awaiting processing
				rows.each do |r|
					@controller.database.update_torrent_state(r[0], "awaiting processing")
					@controller.log( "State set to awaiting processing: #{r[1]}" )
				end
				
		end
		  
	  
		###
		# Remove torrents from DB that have been removed from utorrent
		#
		# torrents:: torrents that have been removed
		#
		def remove_torrents(torrents)
			$LOG.debug "Processor::remove_torrents( torrents )"
			
				# From DB - Get list of torrents that are awaiting removal
				q = "SELECT hash, name FROM torrents WHERE tp_state = \"awaiting removal\";"
				rows = @controller.database.execute(q)
				
				# For each torrent in awaiting list, remove it if the removed list contains its hash
				rows.each do |r|
					if torrents.has_key?(r[0])
						# Remove it from DB and removal list
						@controller.database.delete_torrent( r[0] )
						torrents.delete( r[0] )
						# Log it
						@controller.log( "Torrent removed (as requested): #{r[1]}" )
					end
				end
				
				# For remaining torrents in removal list, remove them from DB and removal list
				torrents.each do |hash, t|
					@controller.database.delete_torrent( hash )
					# Log it
					@controller.log( "Torrent removed (NOT requested): #{t.name}" )
				end
				
		end
		  
	  
		###
		# Remove torrents from DB that have been removed from utorrent
		#
		# torrents:: current list of torrents passed from utorrent
		#
		def remove_missing_torrents(torrents)
			$LOG.debug "Processor::remove_missing_torrents( torrents )"
			
				@controller.log( "Removing (pending removal) torrents from DB that are no longer in the uTorrent list" )
				
				# From DB - Get list of torrents that are awaiting removal
				q = "SELECT hash, name FROM torrents WHERE tp_state = \"awaiting removal\";"
				rows = @controller.database.execute(q)
				
				
				# For each torrent in awaiting list, remove it if the torrent list DOES NOT contains its hash
				removed_count = 0
				rows.each do |r|
					if !torrents.has_key?(r[0])
						# Remove it from DB
						@controller.log( "    Torrent removed from DB: #{r[1]}" )
						@controller.database.delete_torrent( r[0] )
						removed_count += 1
					end
				end
				
				@controller.log("    No torrents were removed.") if (removed_count < 1)
		end
		  
	  
		###
		# Process torrents that are awaiting processing
		#
		def process_torrents_awaiting_processing()
			$LOG.debug "Processor::process_torrents_awaiting_processing()"
			
				# Get list of torrents from DB where state = awaiting processing
				q = "SELECT hash, name, folder, label FROM torrents WHERE tp_state = \"awaiting processing\";"
				rows = @controller.database.execute(q)
				
				# For each torrent, process it
				rows.each do |r|
					hash = r[0]
					fname = r[1]
					fdir = r[2]
					lbl = r[3]
					
					@controller.log( "Processing torrent: #{fname} (in #{fdir})" )
					success = copy_torrent( hash, fname, fdir, lbl)
					
					# For each torrent, if processed successfully (file copied), set state = processed
					@controller.database.update_torrent_state( hash, "processed" ) if success
					@controller.log( "    Torrent processed successfully: #{fname}" ) if success
					@controller.log( "    ERROR: Torrent NOT processed successfully: #{fname}" ) unless success
				end
				
		end
		  
	  
		###
		# Copy torrent files to a specific location
		#
		#
		def copy_torrent( hash, fname, fdir, lbl)
			$LOG.debug "Processor::copy_torrent( #{hash}, #{fname}, #{fdir}, #{lbl} )"
			appPath = "robocopy"
			
			# Setup the destination processing folder path.
			destPath = @controller.cfg[:otherprocessing]
			destPath = @controller.cfg[:tvprocessing]			if (lbl.include?("TV"))
			destPath = @controller.cfg[:movieprocessing]	if (lbl.include?("Movie"))
			
			# Handle situation where the torrent is in a subfolder.
			pathTail = ""
			cmdLineSwitch = ""
			isSubDir = false
			
			if (!fdir.include?( @dir_completed_download ))
				@controller.log("    ERROR: Downloaded Torrent is not in the expected location.")
				@controller.log("           Torrent location: #{fdir}")
				@controller.log("           Expected location: #{@dir_completed_download} -- or a subdirectory of this location.")
				@controller.log("    Copy operation will be attempted later.")
				return false
			end
			
			if (fdir != @dir_completed_download)
				isSubDir = true
				pathTail = fdir.split(@dir_completed_download)[1]
				cmdLineSwitch = "/E"
				# If we're using the /E switch (copy empty subdirs) we do NOT want to provide a filename (we're copying the entire dir):
			end
			
			destPath += pathTail
			cmdLine = "#{quote(fdir)} #{quote(destPath)} #{quote(fname)}"
			cmdLine = "#{quote(fdir)} #{quote(destPath)} #{cmdLineSwitch}" unless !isSubDir
			appCmd = "#{appPath} #{cmdLine}"
			@controller.log "Executing: #{appCmd}"
	
			result = Kernel.system("#{appCmd}")
			if result
					@controller.log ("    ERROR: #{appPath} failed. Command line it was called with: ".concat(appCmd) )
					return false
			end
		
			targetPath = "#{destPath}\\#{fname}"
			targetPath = "#{destPath}" unless !isSubDir
			if( !File.exists?(targetPath) )
					@controller.log ("    ERROR: Unable to verify that target exists. Target path: #{targetPath}")
					@controller.log ("    ERROR: #{appPath} failed to copy file. Command line it was called with: ".concat(appCmd) )
					return false
			end
			
			return true
			
		end
		
		
		###
		# Quote a string
		#
		# str:: String to apply quotes to
		#
		def quote(str)
			return "\"#{str}\""
		end
		
		
		###
		# Process torrents that have completed processing
		#
		def update_torrents_completed_processing()
			$LOG.debug "Processor::update_torrents_completed_processing()"
			
				# Get list of torrents from DB where state = processed
				q = "SELECT hash, name FROM torrents WHERE tp_state = \"processed\";"
				rows = @controller.database.execute(q)

				# For each torrent, set state = seeding
				rows.each do |r|
					@controller.database.update_torrent_state( r[0], "seeding" )
					@controller.log( "State set to seeding: #{r[1]}" )
				end
				
		end
		  
	  
		###
		# Process torrents that have completed seeding
		#
		def process_torrents_completed_seeding()
			$LOG.debug "Processor::process_torrents_completed_seeding()"
			
				# Get list of torrents from DB where state = seeding
				q = "SELECT hash, ratio, name FROM torrents WHERE tp_state = \"seeding\";"
				rows = @controller.database.execute(q)

				# For each torrent, if ratio >= (target ratio - 1)
				rows.each do |r|
					if ( Integer(r[1]) >= (@seed_ratio - 1) )
						# Set state = awaiting removal
						@controller.database.update_torrent_state( r[0], "awaiting removal" )
						@controller.log( "State set to awaiting removal: #{r[2]}" )
						
						# Request removal via utorrent
						utorrent.remove_torrent( r[0] )
						@controller.log( "Removal request sent: #{r[2]}" )
					end
				end
				
		end
		  
	  
		###
		# Run interactive console
		#
		def interactiveMode()
			$LOG.debug "Processor::interactiveMode"
			
			console = Console.new(@controller)
			console.verbose = @verbose
			
			console.execute
		end
		  
	  
		###
		# Test if app is locked
		#
		def appLocked?()
			$LOG.debug "Processor::appLocked?()"
			
			return true if @controller.database.read_lock() == "Y"
			
			return false
		end
		  
	  
		###
		# Set application lock flag
		#
		def lockApp()
			$LOG.debug "Processor::lockApp()"
			
			@controller.database.aquire_lock()
		end
		  
	  
		###
		# UnSet application lock flag
		#
		def unlockApp()
			$LOG.debug "Processor::unlockApp()"
			
			@controller.database.release_lock()
		end
		  
	  
	end # class Processor



end # module TorrentProcessor
