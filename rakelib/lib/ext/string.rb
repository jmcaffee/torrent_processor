##############################################################################
# File::    string.rb
# Purpose:: Monkey Patch String class to add snakecase method
# 
# Author::    Jeff McAffee 02/22/2015
# Copyright:: Copyright (c) 2015, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

class String
  def snakecase
    # Strip the following characters out: /, (, )
    # Replace :: with /
    # Separate CamelCased text with _
    # Replace space with _
    # Replace - with _
    # Replace multiple _ with one _
    self.gsub("/", '').
    gsub("(",'').
    gsub(")",'').
    gsub("#",'').
    gsub("&",'').
    gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    gsub(" ",'_').
    tr("-", "_").
    gsub(/(_)+/,'_').
    downcase
  end
end

