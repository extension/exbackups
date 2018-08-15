# === COPYRIGHT:
# Copyright (c) 2015 North Carolina State University
# === LICENSE:
# see LICENSE file
require 'thor'
require 'exbackups'

module Exbackups
  class CLI < Thor
    include Thor::Actions

    desc "about", "About eXbackups"
    def about
      puts "eXbackups Version #{Exbackups::VERSION}: Master backup management utility for eXtension"
    end

    desc "ping", "Send a ping post to the backup logging server"
    method_option :quiet,  :type => :boolean, :default => false, :aliases => "-q", :desc => "Don't show verbose output"
    def ping
      pinger = Exbackups::Ping.new
      result = pinger.post
      if(result.success)
        say "Success: #{result.message}" if(!options[:quiet])
      else
        say "Error: #{result.message}"
      end
    end

    desc "test", "Post a test backup log to the backup logging server"
    method_option :error, :default => false, :aliases => ["-e","--error"], :desc => "Indicate an 'error' in the test log"
    method_option :quiet,  :type => :boolean, :default => false, :aliases => "-q", :desc => "Don't show verbose output"
    def test
      testhostname = options[:error] ? Exbackups::TEST_ERROR_HOST : Exbackups::TEST_HOST
      backup = Exbackups::Backup.new(testhostname)
      say "Posting an backup log for '#{testhostname}'"
      result = backup.go_forth_and_backup
      if(result.success)
        say "Success: #{result.message}"
      else
        say "Error: #{result.message}" if(!options[:quiet])
      end
    end

    desc "hosts", "List the known backup hosts in the configuration file"
    def hosts
      known_hosts = Exbackups.settings.backuphosts.to_hash
      if(known_hosts.empty?)
        say "No hosts are listed for backups on this system"
      else
        say "The following backuphosts are listed on this system:"
        known_hosts.each do |host,fqdn|
          say "#{host} (#{fqdn})"
        end
      end
    end

    desc "backup", "Run a backup for all hosts or a specific host"
    method_option :host, :default => 'all', :aliases => ["-h","--host"], :desc => "Host to backup (or 'all')"
    method_option :quiet,  :type => :boolean, :default => false, :aliases => "-q", :desc => "Don't show verbose output"
    def backup
      host = options[:host]
      known_hosts = Exbackups::Backup.host_list
      if(host == 'all')
        known_hosts.each do |hostname|
          backup = Exbackups::Backup.new(hostname)
          result = backup.go_forth_and_backup
          if(result.success)
            say "#{hostname} backup success: #{result.message}" if(!options[:quiet])
          else
            say "#{hostname} backup error: #{result.message}"
          end
        end
      elsif(known_hosts.include?(host))
        backup = Exbackups::Backup.new(host)
        result = backup.go_forth_and_backup
        if(result.success)
          say "#{host} backup success: #{result.message}" if(!options[:quiet])
        else
          say "#{host} backup error: #{result.message}"
        end
      else
        say("#{host} is not a configured backup host. Configured backup hosts are: #{known_hosts.join(', ')}")
        exit(1)
      end
    end

    desc "backupcommand", "Show the backup command to be executed for all hosts or a specific host"
    method_option :host, :default => 'all', :aliases => ["-h","--host"], :desc => "Host to backup (or 'all')"
    def backupcommand
      host = options[:host]
      known_hosts = Exbackups::Backup.host_list
      if(host == 'all')
        known_hosts.each do |hostname|
          backup = Exbackups::Backup.new(hostname)
          say "Command for host: #{hostname}"
          say "  #{backup.backupcommand}"
          say "  #{backup.cleanupcommand}"
        end
      elsif(known_hosts.include?(host))
        backup = Exbackups::Backup.new(host)
        say "Command for host: #{host}"
        say "  #{backup.backupcommand}"
        say "  #{backup.cleanupcommand}"
      else
        say("#{host} is not a configured backup host. Configured backup hosts are: #{known_hosts.join(', ')}")
        exit(1)
      end
    end

  end

end
