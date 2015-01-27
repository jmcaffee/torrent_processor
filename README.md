# TorrentProcessor README


## Summary

TorrentProcessor acts as the middle-man between your BitTorrent client
and your media manager application (I use SickBeard).

Its job is to copy the downloaded torrents to specific directories as
soon as the file has completed downloading. It copies, not moves, the
files so you can continue to seed the torrent.

TorrentProcessor also performs other processing tasks such as:

- Extract RAR archives
- Rename files based on filters
- Rename movie file names - looks up the movie name via online database
- Set seeding limits based on a torrent's tracker url
- Clean up torrents that have completed seeding


## Requirements

TorrentProcessor works with the uTorrent BitTorrent client.

Additional applications are needed to perform some tasks (all free):

- Robocopy - for copying/moving files
- 7-Zip    - for extracting RAR archives
- TMdb API - for looking up movie info


## Installing


### Robocopy

If you're running TorrentProcessor on Windows 7 or better, Robocopy
is a part of the OS so there's no need to install it separately.

If you're on XP, download Robocopy from [microsoft](http://download.microsoft.com/download/f/d/0/fd05def7-68a1-4f71-8546-25c359cc0842/UtilitySpotlight2006_11.exe)
and install it.


### 7-Zip

Download 7-Zip from [SourceForge](http://downloads.sourceforge.net/sevenzip/7z920.exe) and install it.
Note the path to the install location.


### TMdb

You'll need to signup for a TMdb api key if you want to use the movie
renaming functionality.

Go to [The Movie Database](https://www.themoviedb.org/account) and create an account.
After you've set up an account, log into your account and generate a new API key
from within the 'API' section.

When filling out the requested fields, do NOT use the word 'torrent'
or you will be denied.

After a few minutes, you'll receive an email that takes you to a page where
your API key is located.

Copy the API key and save it.


## Configuration

The first time TorrentProcessor is run, you'll need to configure it.

Start TorrentProcessor with the --init command line option.

    cd YOUR\INSTALL\LOCATION
    TorrentProcessor.exe --init

Complete the questions with your information.

$$ List out the questions and what they are for $$


## Scheduling



= File:   README.txt
= Purpose:  Additions, modifications and notes for TorrentProcessor.
=
= Copyright:  Copyright (c) 2011-2014, kTech Systems LLC. All rights reserved.
= Website:    http://ktechsystems.com
========================================================================

BUILDING THE PROJECT:

  Rake is used to build and install the project. By default, rake
  will run all specs.

  Tasks to take note of:


    rake spec             # Runs all specs
    rake spec_pretty      # Output spec results in document format
    rake dist             # Clean, uninstall all versions of torrentprocessor
                            gem, build the gem, install the gem,
                            create the OCRA executable and create the
                            installer (will be found in build dir).
    rake exe              # Builds the OCRA executable
    rake exe_installer    # Builds the OCRA executable and installer

  So, to build the project:
    rake spec   # make sure everything is good.
    rake dist   # build installer
  
