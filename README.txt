========================================================================
= File:   README.txt
= Purpose:  Additions, modifications and notes for TorrentProcessor.
=
= Copyright:  Copyright (c) 2011-2014, kTech Systems LLC. All rights reserved.
= Website:    http://ktechsystems.com
========================================================================

BUILDING THE PROJECT:

  Rake is used to build and install the project. By default, rake
  will run all specs.

  The available tasks are:


    rake clean            # Remove any temporary products
    rake clobber          # Remove any generated file
    rake clobber_package  # Remove package products
    rake clobber_rdoc     # Remove rdoc products
    rake exe              # Build an OCRA executable
    rake gem              # Build a rubygem in the pkg dir
*   rake help             # Documentation for building gem and executable (Ocra)
    rake package          # Build all the packages
    rake pkg_list         # List files to be included in gem
    rake rdoc             # Build the rdoc HTML Files
    rake rebuild          # rebuild project -- clean, install, test
    rake repackage        # Force a rebuild of the package files
    rake rerdoc           # Force a rebuild of the RDOC files
