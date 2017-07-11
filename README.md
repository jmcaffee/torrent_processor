TorrentProcessor
===============================================================================

Summary
-------------------------------------------------------------------------------

TorrentProcessor acts as the middle-man between your BitTorrent client
and your media manager application (I use SickBeard [now, SickRage]).

Its job is to copy the downloaded torrents to specific directories as
soon as the file has completed downloading. It copies, not moves, the
files so you can continue to seed the torrent.

TorrentProcessor also performs other processing tasks such as:

- Extract RAR archives
- Rename files based on filters
- Rename movie file names - looks up the movie name via online database
- Set seeding limits based on a torrent's tracker url
- Clean up torrents that have completed seeding

- - -

Requirements
-------------------------------------------------------------------------------

TorrentProcessor works with either uTorrent or qBitTorrent Bit Torrent
applications.

__Note:__ uTorrent's WebUI has gotten extremely slow over the last few
releases. It now takes ~ 2 mins. to get a list of torrents.

__Note: qBitTorrent doesn't support setting seed ratios via WebUI (yet).__
TorrentProcessor will set an internal limit based on tracker filters, and not
remove torrents that meet the criteria, but it is up to the user to set the
share limit on each torrent from within the app itself.

Additional applications are needed to perform some tasks (all free/open source):

- Robocopy - for copying/moving files (on windows)
- 7-Zip    - for extracting RAR archives
- TMdb API - for looking up movie info

- - -

Installing Dependencies
-------------------------------------------------------------------------------

### Robocopy

If you're running TorrentProcessor on Windows 7 or better, Robocopy
is a part of the OS so there's no need to install it separately.

If you're on XP, download Robocopy from [microsoft](http://download.microsoft.com/download/f/d/0/fd05def7-68a1-4f71-8546-25c359cc0842/UtilitySpotlight2006_11.exe)
and install it.

For Linux, TorrentProcessor uses the built-in copy mechanism.

### 7-Zip

#### Windows

Download 7-Zip from [SourceForge](http://downloads.sourceforge.net/sevenzip/7z920.exe) and install it.
Note the path to the install location.

#### Linux

Install 7-Zip using `apt-get`

    sudo apt-get install -y p7zip-full


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

- - -

Installing TorrentProcessor
-------------------------------------------------------------------------------

Build the jar/archive using instructions found in the **Building** section
below.

### Windows

Move the `.jar` file to a location on your `path` or add the location to
your `path`.

### Linux

Extract the `torrent_processor-*-.7z` and run the installer script with sudo:

    sudo ./install.sh

The install script will install TorrentProcessor to `/usr/local/src/` and
create a link in `/usr/local/bin`.

The uninstall script will remove the link and src directories.

If updating, run the `uninstall.sh` to remove the old version, then run the
`install.sh` script to install the new version.

You should keep your configuration files in your home dir (or a subdirectory
of your home dir [`.torrentprocessor` by default]) so uninstalling and
reinstalling the app will not mess with your configuration.

- - -

Configuration
-------------------------------------------------------------------------------

The first time TorrentProcessor is run, you'll need to configure it.

Start TorrentProcessor with the `--init` command line option.

### Windows

    cd YOUR\INSTALL\LOCATION
    torrent_processor.cmd --init

### Linux

    torrent_processor --init

Complete the questions with your information.

_$$ List out the questions and what they are for $$_

- - -

Scheduling
-------------------------------------------------------------------------------

### Windows

_$$ ToDo $$_

### Linux

#### Cron

Additional info for Ubuntu can be found at
[help.ubuntu.com](https://help.ubuntu.com/community/CronHowto).

Create a cron task to run `torrent_processor` once every hour:

    crontab -e

In the editor, enter

    05 * * * * /usr/local/bin/torrent_processor

The example above will run `torrent_processor` every hour at 5 minutes after
the top of the hour.

- - -

Building
-------------------------------------------------------------------------------

Make sure you're using jruby to build the app distro.

    switchruby

It should say `jruby-9.0.5.0`

The following rake tasks will clean the build and dist dirs, then build
the jars and scripts, and bundle the result into a 7-zip (`7z`) archive.

    rake build:clean dist:clean dist

The distro can be found in `dist`.

Additional tasks can be listed with

    rake -T

### Cannot run program "ant"

If you see the this error while building or running `rake`, you'll need to
install `ant` (the `puck` gem uses ant to build the final jars).

    sudo apt-get install -y ant

- - -

Testing
-------------------------------------------------------------------------------

Testing with `guard` works better when running MRI ruby compared to jruby.
For this reason, there's a script to make it easy to switch between the two
rubies: `switchruby`

Before starting guard, switch out of jruby.

    switchruby

To successfully run the TMDb tests, you'll need your TMDb API key (see above).
Create a file named `.envsetup` in the project root containing the following:

    #!/bin/bash
    # vi: ft=shell

    export TMDB_API_KEY=PUT_YOUR_KEY_HERE

Replace `PUT_YOUR_KEY_HERE` with your API key and save it.

Before running tests, in the terminal you'll start the tests from,
source `.envsetup` file, then run your tests.
The tests will look for the API key in the environment variables.

    $ source ./.envsetup
    $ bundle exec rspec

Or, if using guard:

    $ source ./.envsetup
    $ bundle exec guard

`.envsetup` is ignored in `.gitignore` so you don't have to worry about your
API key getting uploaded/committed to the repo.

- - -

Contributing
-------------------------------------------------------------------------------

1. Fork it ( https://github.com/jmcaffee/torrent_processor/fork )
1. Clone it (`git clone git@github.com:[my-github-username]/torrent_processor.git`)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Create tests for your feature branch
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request

