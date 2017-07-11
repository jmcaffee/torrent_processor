##############################################################################
#    Copyright (C) 2017  Jeff McAffee
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

module TorrentProcessor

  VERSION = "2.0.0.beta" unless constants.include?("VERSION")
  APPNAME = "TorrentProcessor" unless constants.include?("APPNAME")
  COPYRIGHT = "Copyright (C) 2017 Jeff McAffee" unless constants.include?("COPYRIGHT")



  def self.logo()
    return  [ "#{TorrentProcessor::APPNAME} v#{TorrentProcessor::VERSION}",
              "#{TorrentProcessor::COPYRIGHT}",
              "",
              "This program comes with ABSOLUTELY NO WARRANTY.",
              "This is free software, and you are welcome to redistribute it",
              "under certain conditions; see LICENSE.txt for details.",
              ""
            ].join("\n")
  end


end # module TorrentProcessor
