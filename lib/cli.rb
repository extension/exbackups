# === COPYRIGHT:
# Copyright (c) 2015 North Carolina State University
# === LICENSE:
# see LICENSE file
require 'thor'
require 'getdata'
require 'highline'

module Exbackups
  class CLI < Thor
    include Thor::Actions

    # these are not the tasks that you seek
    def self.source_root
      File.expand_path(File.dirname(__FILE__) + "/..")
    end

    no_tasks do

    end

    desc "about", "About eXbackups"
    def about
      puts "eXbackups Version #{Exbackups::VERSION}: Master backup management utility for eXtension"
    end
    
  end

end
